# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Authentication
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  before_filter :get_selected_practitioner
  before_filter :set_locale
  
  def set_locale
    I18n.locale = extract_locale_from_subdomain
  end
  
  def extract_locale_from_subdomain
    parsed_locale = request.subdomains.first.try(:to_sym)
    (I18n.available_locales.include? parsed_locale) ? parsed_locale  : nil
  end
      
  def get_phone_prefixes
    @phone_prefixes = Client::PHONE_SUFFIXES    
  end
  
  def get_practitioners
    @practitioners = Practitioner.find(:all, :order => "first_name, last_name")
  end
  
  def get_selected_practitioner
    #check the URL
    if !params[:id].nil?
      @current_selected_pro = Practitioner.find_by_permalink(params[:id])
      unless @current_selected_pro.nil?
        cookies[:selected_practitioner_id] = @current_selected_pro.id 
      end
    end
    if !params[:practitioner_id].nil?
      @current_selected_pro = Practitioner.find_by_permalink(params[:practitioner_id])      
      cookies[:selected_practitioner_id] = @current_selected_pro.id unless @current_selected_pro.nil?
    end
    #fall back on the cookie
    if @current_selected_pro.nil? && !cookies[:selected_practitioner_id].blank?
      begin
        @current_selected_pro = Practitioner.find(cookies[:selected_practitioner_id])
      rescue ActiveRecord::RecordNotFound
        cookies.delete(:selected_practitioner_id)
      end
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
