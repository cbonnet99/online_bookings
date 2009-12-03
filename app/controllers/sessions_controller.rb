class SessionsController < ApplicationController
  def new
  end
  
  def create
    client = Client.authenticate(params[:login], params[:password])
    if client
      session[:client_id] = client.id
      flash[:notice] = "Logged in successfully."
      redirect_to_target_or_default(root_url)
    else
      flash.now[:error] = "Invalid login or password."
      render :action => 'new'
    end
  end
  
  def destroy
    session[:client_id] = nil
    flash[:notice] = "You have been logged out."
    redirect_to root_url
  end
end
