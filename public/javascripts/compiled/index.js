/* DO NOT MODIFY. This file was compiled Sat, 12 Mar 2011 20:38:53 GMT from
 * /Users/nickelser/Development/bgrams/app/coffeescripts/index.coffee
 */

(function() {
  var init;
  init = function() {
    common_init();
    if (!_settings.logged_in) {
      return $('.game_link').click(function(e) {
        e.preventDefault();
        log("loading overlay!");
        window._after_url = $(this).attr('href');
        return open_login_overlay(false, "gotta sign in to join a game");
      });
    }
  };
  $(function() {
    return _.defer(function() {
      return init();
    });
  });
}).call(this);
