# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Authentication
  include Authentication
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def get_phone_prefixes
    @phone_prefixes = Client::PHONE_SUFFIXES    
  end
  
  def get_practitioners
    @practitioners = Practitioner.all
  end
  
  def get_selected_practitioner
    #check the URL
    if !params[:practitioner_permalink].nil?
      @current_selected_pro = Practitioner.find_by_permalink(params[:practitioner_permalink])
      unless @current_selected_pro.nil?
        cookies[:selected_practitioner_id] = @current_selected_pro.id 
      end
    end
    if !params[:practitioner_id].nil?
      @current_selected_pro = Practitioner.find_by_permalink(params[:practitioner_id])
      unless @current_selected_pro.nil?
        cookies[:selected_practitioner_id] = @current_selected_pro.id 
      end
    end
    #fall back on the cookie
    if @current_selected_pro.nil? && !cookies[:selected_practitioner_id].nil?
      @current_selected_pro = Practitioner.find(cookies[:selected_practitioner_id])
    end    
  end
  
  def require_selected_practitioner
    unless pro_logged_in?
      get_selected_practitioner
      #otherwise ask the client to select a practitioner
      if @current_selected_pro.nil?
        respond_to do |format|
          format.json do
            flash[:error] = "No selected practitioner"
            redirect_to flash_url
          end
          format.html do
            redirect_to edit_selected_practitioner_url
          end
        end
      end
    end
  end
  
end
