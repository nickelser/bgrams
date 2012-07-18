class Players::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    @player = Player.find_for_facebook_oauth(env["omniauth.auth"], current_player)

    if @player.persisted?
      flash[:notice] = "logged in with facebook"
      sign_in_and_redirect @player, :event => :authentication
    else
      session["devise.facebook_data"] = env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end