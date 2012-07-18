class Players::RegistrationsController < Devise::RegistrationsController
  def create
    @player = build_resource(params[:player])
    if @player.save
      set_flash_message(:notice, :signed_up)
      sign_in @player
      render :status => 200, :json => ""
    else
      clean_up_passwords @player
      render :status => 406, :json => @player.errors
    end
  end
end