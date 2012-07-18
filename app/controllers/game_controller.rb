class GameController < ApplicationController
  include GameHelper
  include GameSerialize
  
  before_filter :authenticate_player!, :except => [:play]
  before_filter :set_game, :except => [:play, :pusher_auth]
  before_filter :game_in_progress, :only => [:load_game, :update_board, :pgram, :dump]
  before_filter :game_waiting_for_start, :only => [:update_lobby, :add_to_lobby, :remove_from_lobby, :ready]
  
  # non-ajax
  def play
    game = Game.where(game_query(params[:id])).first
    
    if game
      unless player_signed_in?
        # js will show authentication box
        return
      end
      
      unless game.state == Game::IN_PROGRESS
        if game.lobby_players.length < Game::MAX_PLAYERS_PER_GAME
          game.add_player_to_lobby(current_player)
        else
          redirect_to :root, :alert => "game has too many players, you can't join :("
          return
        end
        
        set_game(game.reload)
        
        @game.channel.trigger_async('joined', {'name' => current_player.username, 'id' => current_player.id,
                                         'ready' => @game.ready_players, 'total' => @game.lobby_players.length})
        
        return
      else
        unless set_game(game, false)
          redirect_to :root, :alert => "game already started, you can't join :("
          return
        end
        
        return
      end
    end
    
    redirect_to :root, :alert => "game not found :("
  end

  # pusher integration
  def pusher_auth
    logger.debug "pusher auth: #{current_player.id}"
    game_id = params[:channel_name].match /presence-game-(\w+)/
    if game_id && current_player && set_game(Game.find(game_id[1]), false)
      render :json => Pusher[params[:channel_name]].authenticate(params[:socket_id], {:user_id => current_player.id, :name => current_player.username})
    else
      render :text => "not authorized", :status => '403'
    end
  end
  
  # initial loads
  def update_lobby
    # disabled for now :)
    #@game.set_lobby params[:players]
    #check_for_start
    package_and_return_data
  end
  
  def add_to_lobby
    @game.raw_add_player_to_lobby params[:player] unless params[:player].blank?
    package_and_return_data
  end
  
  def remove_from_lobby
    @game.raw_remove_player_from_lobby params[:player] unless params[:player].blank?
    check_for_start
    package_and_return_data
  end
  
  def ready
    @game.add_player(current_player)
    @game.channel.trigger_async('player_ready', {'ready' => @game.ready_players, 'total' => @game.lobby_players.count, 'player' => current_player.id})
    
    check_for_start
    
    @ret = {'ready' => @game.ready_players, 'total' => @game.lobby_players.count}
    
    package_and_return_data
  end
  
  def load_game
    @ret = { 'letters' => @session_player.letters, 'board' => serialize_board(@session_player.board), 'game_state' => @game.state, 'num_remain' => @game.letters_remaining,
             'id' => current_player.id, 'players' => @game.players.select { |p| p.id != @session_player.id }.map { |p| player_details(p) } }
    package_and_return_data
  end
  
  # AJAX api
  def chat
    message = params[:message]
    
    unless message.blank?
      @game.channel.trigger_async('chat', {'player' => current_player.id, 'message' => message}, params[:socket_id])
    end
    
    package_and_return_data
  end
  
  # check gamestate for these ops
  def update_board
    d = params[:delta]
    
    unless d.blank?
      @game.channel.trigger_async('update', {'player' => current_player.id, 'delta' => d}, params[:socket_id]) if @session_player.update_board(d)
    end
    
    package_and_return_data
  end
  
  def pgram
    d = params[:delta]
    unless d.blank?
      @game.channel.trigger_async('update', {'player' => current_player.id, 'delta' => d}, params[:socket_id]) if @session_player.update_board(d)
    end
    
    @game.reload
    reload_session_player
    ok, status = @game.pgram @session_player
    
    if ok
      @game.reload
      nr =  @game.letters_remaining
      
      if status[:bgrams]
        @game.channel.trigger_async('bgrams', {'player' => current_player.id, 'num_remain' =>  nr})
        @game.state = Game::WAITING_FOR_START
        @game.session += 1
        @game.save!
        @session_player.won = true
        @session_player.save!
      else
        @game.channel.trigger_async('peel', {'player' => current_player.id, 'new_tiles' => status[:new_tiles], 'num_remain' =>  nr}, params[:socket_id])
        @ret = {'new_letters' => status[:new_tiles], 'num_remain' => nr}
      end
      
      package_and_return_data
      return
    end
    
    package_and_return_data(false, status)
  end
  
  def dump
    unless (letters = @game.dump(@session_player, params[:letter])).blank?
      nr = @game.reload.letters_remaining
      @game.channel.trigger_async('dump', {'player' => current_player.id, 'letters' => letters, 'num_remain' => nr}, params[:socket_id])
      @ret = {'new_letters' => letters, 'num_remain' => nr}
      
      package_and_return_data
      return
    end
    
    package_and_return_data(false, "bad letter >:|")
  end
  
  protected
  
  def player_details(sp)
    pp = sp.player
    
    logger.debug "SP: "+sp.inspect
    { 'name' => pp.username, 'id' => pp.id, 'board' => serialize_board(sp.board), 'letters'  => sp.letters, 'won' => sp.won }
  end
  
  def reload_session_player
    @session_player = @game.players.where(:player_id => current_player.id).first unless @game.blank?
  end

  def set_game(game = nil, render = true)
    if !game.nil? || !params.has_key?(:game_id).blank?
      @game = game || Game.where(game_query(params[:game_id])).first
    end
    
    if @game.nil?
      package_and_return_data(false, "invalid game") if render
      return
    end
    
    if @game.state == Game::IN_PROGRESS
      reload_session_player
    else
      # set session player to true to indicate they are in the the lobby (if they are...)
      if @game.player_in_lobby?(current_player)
        @session_player = true
      end
    end
    
    # no valid game found, oops
    if @session_player.nil?
      package_and_return_data(false, "you aren't in this game, holmes") if render
      return false
    end
    
    true
  end
  
  def game_in_progress
    if !@game || @game.state != Game::IN_PROGRESS
      package_and_return_data(false, "game not in progress!")
    end
  end
  
  def game_waiting_for_start
    if !@game || @game.state != Game::WAITING_FOR_START
       package_and_return_data(false, "game already in progress!")
     end
  end
  
  def package_and_return_data(ok = true, error_data = nil)
    status = ok ? 200 : 406
    ret = ok ? (@ret || true) : error_data
    logger.debug "packaging: "+ret.to_json.inspect
    respond_to do |format|
      format.json { render :status => status, :json => ret.to_json }
      format.html { render :status => status, :text => ret.to_json }
    end
  end
  
  def check_for_start
    return unless @game.state == Game::WAITING_FOR_START
    
    urp = @game.reload.unready_players
    
    if urp == 0
      initial_tiles = @game.start()
      @game.channel.trigger_async('start', {'initial_tiles' => initial_tiles, 'num_remain' => @game.reload.letters_remaining})
    end
  end
  
  def game_query(id_str)
    return {0 => 0} if id_str.blank?
    
    pid = nil
    
    begin
      pid = BSON::ObjectId(id_str)
    rescue BSON::InvalidObjectId
      # nope!
    end
    
    if pid
      {:_id => pid, :private => true}
    else
      {:short_id => id_str.to_i, :private => false}
    end
  end
end
