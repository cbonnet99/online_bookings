class SessionsController < ApplicationController
  def create
    pro = Practitioner.authenticate(params[:email], params[:password])
    if pro
      session[:pro_id] = pro.id
      flash[:notice] = I18n.t(:flash_notice_session_welcome) + "#{APP_CONFIG[:site_name]}"
      redirect_to practitioner_url(pro)
      # redirect_to_target_or_default(pro)
    else
      flash.now[:error] = I18n.t(:flash_error_session_invalid_login_password)
      render :action => 'new'
    end
  end
  
  def destroy
    session[:client_id] = nil
    session[:pro_id] = nil
    cookies[:email] = nil
    cookies[:selected_practitioner_id] = nil
    flash[:notice] = I18n.t(:flash_notice_session_logout)
    redirect_to root_url
  end
end
