class SessionsController < ApplicationController
  def create
    pro = Practitioner.authenticate(params[:email], params[:password])
    if pro
      session[:pro_id] = pro.id
      flash[:notice] = "Welcome to #{APP_CONFIG[:site_name]}"
      redirect_to pro
      # redirect_to_target_or_default(pro)
    else
      flash.now[:error] = "Invalid login or password."
      render :action => 'new'
    end
  end
  
  def destroy
    session[:client_id] = nil
    session[:pro_id] = nil
    cookies[:selected_practitioner_id] = nil
    flash[:notice] = "You have been logged out."
    redirect_to root_url
  end
end
