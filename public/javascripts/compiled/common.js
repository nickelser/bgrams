/* DO NOT MODIFY. This file was compiled Fri, 25 Mar 2011 07:28:39 GMT from
 * /Users/nickelser/Development/bgrams/app/coffeescripts/common.coffee
 */

(function() {
  if (_settings.debug || location.hash === '#debug') {
    window.WEB_SOCKET_DEBUG = true;
    /*
    window.log = ->
      if arguments.callee.caller.name.length > 1
        name = arguments.callee.caller.name+'(): '
      else
        name = ''
      window.console.log(name, arguments)
    */
    window.log = function() {
      return window.console.log.apply(window.console, arguments);
    };
  } else {
    window.log = (function() {
      return false;
    });
  }
  window.common_init = function() {
    var effect;
    log("logged in?", _settings.logged_in);
    if ($('#alert').html().length > 2) {
      $.noticeAdd({
        text: $('#alert').html(),
        type: "alert"
      });
    }
    if ($('#notice').html().length > 2) {
      $.noticeAdd({
        text: $('#notice').html(),
        type: "notice"
      });
    }
    if (!($.browser && $.browser.webkit)) {
      $.noticeAdd({
        text: "please use chrome or safari :'(",
        type: "alert"
      });
    }
    if (!_settings.logged_in) {
      if ($.browser.mozilla) {
        effect = 'default';
      } else {
        effect = 'apple';
      }
      $('#login_box').overlay({
        top: 'center',
        oneInstance: true,
        effect: effect,
        closeOnClick: false,
        closeOnEsc: false,
        mask: {
          color: '#444',
          loadSpeed: 200,
          opacity: 0.9
        }
      });
      window.open_login_overlay = function(hide_close, msg) {
        var lb, o;
        if (msg == null) {
          msg = '';
        }
        lb = $('#login_box');
        if (hide_close) {
          lb.find('.close').hide();
        } else {
          lb.find('.close').show();
        }
        if (msg) {
          $('#login_message', lb).html(msg);
        } else {
          $('#login_message', lb).html('');
        }
        o = lb.data('overlay');
        $('#do_register .error, #do_login .error', lb).html('');
        $('#player_username_1').focus();
        if (!o.isOpened()) {
          return o.load();
        }
      };
      $('#sign_in_link').click(function(e) {
        e.preventDefault();
        window._after_url = null;
        return open_login_overlay();
      });
      return $('#do_login, #do_register').submit(function(e) {
        var button, do_login;
        e.preventDefault();
        do_login = $(this).attr('id') === 'do_login';
        log("submitting");
        button = $(this).find('button');
        button.attr('disabled', true);
        return $.ajax({
          url: $(this).attr('action'),
          type: 'POST',
          data: $(this).serialize(),
          success: function(data) {
            log("success!");
            if (window._after_url && window._after_url.length) {
              return window.location = window._after_url;
            } else {
              return window.location.reload();
            }
          },
          error: function(data) {
            var errors;
            log("error :-(");
            button.attr('disabled', false);
            if (do_login) {
              return $('#login_errors').html('wrong password/username');
            } else {
              errors = JSON.parse(data.responseText);
              $('#do_register .error').html('');
              return _.each(errors, function(v, k) {
                return $("#" + k + "_error").html("" + (_.last(v)));
              });
            }
          }
        });
      });
    }
  };
}).call(this);
