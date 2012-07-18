#if defined?(PhusionPassenger)
#  PhusionPassenger.on_event(:starting_worker_process) do |forked|
#    if forked
#      EM.kill_reactor
#    end
#    
#    Thread.new {
#      EM.run {
#        EM.fork_reactor {
#          # keep-alive
#          EM::PeriodicTimer.new(30) {}
#        }
#      }
#    }
#    
#    Signal.trap("INT")  { EM.stop }
#    Signal.trap("TERM") { EM.stop }
#  end
#end

# Monkey-patch for Passenger to use the EventMachine reactor.
# This allows the use of EM timers, EM.system/popen, and other async libraries (amqp, em-http-request, etc) inside a Rails process.

# This requires EM.watch which was added to EM's git repo recently. Build an EM gem first:
#   git clone git://github.com/eventmachine/eventmachine
#   cd eventmachine
#   gem build eventmachine.gemspec
#   sudo gem install eventmachine-0.12.9.gem

# Please do not use this in production =)

begin
  require 'eventmachine'
  require 'phusion_passenger/abstract_request_handler'
rescue LoadError
  retry if require 'rubygems'
end

# Monkey-patch follows. Most of these methods were copied directly from passenger/abstract_request_handler.rb and modified slightly.
# #main_loop was broken out into three methods: #main_loop_setup, #main_loop_teardown and #main_loop_tick
# #accept_connection used to call IO.select, but now only deals with @socket

module PhusionPassenger
  module PipeWatch
    def post_init
      self.notify_readable = true
    end
    def notify_readable
      # XXX should only stop after all pending requests on @socket have been processed
      EM.stop
    end
  end

  module SocketWatch
    def initialize main_loop
      @main_loop = main_loop
    end
    def post_init
      self.notify_readable = true
    end
    def notify_readable
      @main_loop.__send__ :main_loop_tick
    rescue EOFError
      # Exit main loop.
      EM.stop
    rescue Interrupt
      # Exit main loop.
      EM.stop
    rescue SignalException => signal
      if signal.message != HARD_TERMINATION_SIGNAL &&
         signal.message != SOFT_TERMINATION_SIGNAL
        raise
      end
    end
  end

  class AbstractRequestHandler
    def main_loop
      EM.run(proc{
        main_loop_setup

        EM.watch(@socket, SocketWatch, self)
        EM.watch(@owner_pipe, PipeWatch)
        EM.watch(@graceful_termination_pipe[0], PipeWatch)
      }, proc{
        main_loop_teardown
      })
    end
  
    private

    def main_loop_setup
      reset_signal_handlers

      @graceful_termination_pipe = IO.pipe
      @graceful_termination_pipe[0].close_on_exec!
      @graceful_termination_pipe[1].close_on_exec!

      @main_loop_thread_lock.synchronize do
        @main_loop_generation += 1
        @main_loop_running = true
        @main_loop_thread_cond.broadcast
      end

      install_useful_signal_handlers
    end
    def main_loop_tick
      client = accept_connection
      begin
        headers, input = parse_request(client)
        if headers
          if headers[REQUEST_METHOD] == PING
            process_ping(headers, input, client)
          else
            process_request(headers, input, client)
          end
        end
      rescue IOError, SocketError, SystemCallError => e
        print_exception("Passenger RequestHandler", e)
      ensure
        # 'input' is the same as 'client' so we don't
        # need to close that.
        # The 'close_write' here prevents forked child
        # processes from unintentionally keeping the
        # connection open.
        client.close_write rescue nil
        client.close rescue nil
      end
      @processed_requests += 1
    end
    def main_loop_teardown
      revert_signal_handlers
      @main_loop_thread_lock.synchronize do
        @graceful_termination_pipe[0].close rescue nil
        @graceful_termination_pipe[1].close rescue nil
        @main_loop_generation += 1
        @main_loop_running = false
        @main_loop_thread_cond.broadcast
      end
    end

    private

    def accept_connection
      client = @socket.accept
      client.close_on_exec!

      # Some people report that sometimes their Ruby (MRI/REE)
      # processes get stuck with 100% CPU usage. Upon further
      # inspection with strace, it turns out that these Ruby
      # processes are continuously calling lseek() on a socket,
      # which of course returns ESPIPE as error. gdb reveals
      # lseek() is called by fwrite(), which in turn is called
      # by rb_fwrite(). The affected socket is the
      # AbstractRequestHandler client socket.
      #
      # I inspected the MRI source code and didn't find
      # anything that would explain this behavior. This makes
      # me think that it's a glibc bug, but that's very
      # unlikely.
      #
      # The rb_fwrite() implementation takes an entirely
      # different code path if I set 'sync' to true: it will
      # skip fwrite() and use write() instead. So here we set
      # 'sync' to true in the hope that this will work around
      # the problem.
      client.sync = true

      # We monkeypatch the 'sync=' method to a no-op so that
      # sync mode can't be disabled.
      def client.sync=(value)
      end

      # The real input stream is not seekable (calling _seek_
      # or _rewind_ on it will raise an exception). But some
      # frameworks (e.g. Merb) call _rewind_ if the object
      # responds to it. So we simply undefine _seek_ and
      # _rewind_.
      client.instance_eval do
        undef seek if respond_to?(:seek)
        undef rewind if respond_to?(:rewind)
      end

      # Set encoding for Ruby 1.9 compatibility.
      client.set_encoding(Encoding::BINARY) if client.respond_to?(:set_encoding)
      client.binmode

      return client
    end
  end
end