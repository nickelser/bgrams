class Players::SessionsController < Devise::SessionsController
  def create 
    resource = warden.authenticate(:scope => resource_name)
    status = resource.nil? ? 401 : 200
    render :status => status, :json => ""
  end
end