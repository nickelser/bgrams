init = ->
  common_init()
  
  if !_settings.logged_in
    $('.game_link').click (e) ->
      e.preventDefault()
      log "loading overlay!"
      window._after_url = $(this).attr('href') # TODO: not ideal...
      open_login_overlay(false, "gotta sign in to join a game")

$ -> 
  _.defer -> init()