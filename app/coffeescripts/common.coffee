# utility functions
if _settings.debug || location.hash == '#debug'
  window.WEB_SOCKET_DEBUG = true
  ###
  window.log = ->
    if arguments.callee.caller.name.length > 1
      name = arguments.callee.caller.name+'(): '
    else
      name = ''
    window.console.log(name, arguments)
  ###
  window.log = -> window.console.log.apply(window.console, arguments)
else
  window.log = (-> false)

window.common_init = ->
  log "logged in?", _settings.logged_in
    
  $.noticeAdd {text: $('#alert').html(), type: "alert"} if $('#alert').html().length > 2
  $.noticeAdd {text: $('#notice').html(), type: "notice"} if $('#notice').html().length > 2
  
  $.noticeAdd {text: "please use chrome or safari :'(", type: "alert"} unless $.browser && $.browser.webkit
  
  if !_settings.logged_in
    if $.browser.mozilla
      effect = 'default'
    else
      effect = 'apple'
    $('#login_box').overlay
      top: 'center'
      oneInstance: true
      effect: effect
      closeOnClick: false
      closeOnEsc: false
      mask:
        color: '#444',
        loadSpeed: 200,
        opacity: 0.9
    
    window.open_login_overlay = (hide_close, msg='') ->
      lb = $('#login_box')
      
      if hide_close
        lb.find('.close').hide()
      else
        lb.find('.close').show()
      
      if msg
        $('#login_message', lb).html(msg)
      else
        $('#login_message', lb).html('')
        
      o = lb.data('overlay')
      $('#do_register .error, #do_login .error', lb).html('')
      $('#player_username_1').focus()
      o.load() unless o.isOpened()
    
    $('#sign_in_link').click (e) ->
      e.preventDefault()
      window._after_url = null
      open_login_overlay()
    
    $('#do_login, #do_register').submit (e) ->
      e.preventDefault()
      do_login = $(this).attr('id') == 'do_login'
      log "submitting"
      button = $(this).find('button')
      button.attr('disabled', true)

      $.ajax
        url: $(this).attr('action')
        type: 'POST'
        data: $(this).serialize()
        success: (data) ->
          log "success!"
          if window._after_url && window._after_url.length
            window.location = window._after_url
          else
            window.location.reload()
        error: (data) ->
          log "error :-("
          button.attr('disabled', false)
          if do_login
            $('#login_errors').html('wrong password/username')
          else
            errors = JSON.parse(data.responseText)
            $('#do_register .error').html('')
            _.each errors, (v, k) ->
              $("##{k}_error").html("#{_.last(v)}")