class ApplicationController < ActionController::Base
  include Authentication
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  before_filter :get_selected_practitioner
  before_filter :set_locale

  def locate_current_user
    @client_ip = request.remote_ip
    geo = GeoIP.new("#{RAILS_ROOT}/geoip/GeoLiteCity.dat")
    g = geo.city(@client_ip)
    if g.nil?
      @current_user_country_code = $default_country_code
    else
      @current_user_country_code = g[2]
    end
  end
  
  def default_country_code
    if I18n.locale.to_s == "fr"
      return "FR"
    else
      return $default_country_code
    end
  end
  
  def set_locale
    I18n.locale = extract_locale_from_subdomain
  end
  
  def extract_locale_from_subdomain
    parsed_locale = request.subdomains.first.try(:to_sym)
    (I18n.available_locales.include? parsed_locale) ? parsed_locale  : nil
  end
  
  def get_country_code_from_subdomain
    res = request.subdomains.first.try(:upcase)
    logger.debug("========= res STEP 1: #{res}")
    if res.blank? || !$available_country_codes.include?(res)
      res = locate_current_user
      logger.debug("========= res STEP 2: #{res}")
    end
    res = $default_country_code if !$available_country_codes.include?(res)
    res
  end
  
  def get_phone_prefixes
    @phone_prefixes = Client::PHONE_PREFIXES    
  end
  
  def get_practitioners(country_code)
    country_code = @current_country_code if country_code.blank?    
    country_code = $default_country_code if country_code.blank?
    @practitioners = Practitioner.find(:all, :conditions => ["country_code = ?", country_code], :order => "first_name, last_name")
  end
  
  def get_selected_practitioner
    #check the URL
    if !params[:id].nil?
      @current_selected_pro = Practitioner.find_by_permalink(params[:id])
      unless @current_selected_pro.nil?
        cookies[:selected_practitioner_id] = @current_selected_pro.id 
        Time.zone = @current_selected_pro.timezone
      end
    end
    if !params[:practitioner_id].nil?
      @current_selected_pro = Practitioner.find_by_permalink(params[:practitioner_id])      
      unless @current_selected_pro.nil?
        cookies[:selected_practitioner_id] = @current_selected_pro.id
        Time.zone = @current_selected_pro.timezone
      end
    end
    #fall back on the cookie
    if @current_selected_pro.nil? && !cookies[:selected_practitioner_id].blank?
      begin
        @current_selected_pro = Practitioner.find(cookies[:selected_practitioner_id])
        Time.zone = @current_selected_pro.timezone
      rescue ActiveRecord::RecordNotFound
        cookies.delete(:selected_practitioner_id)
      end
    end
    if @current_selected_pro.nil?
      @current_country_code = get_country_code_from_subdomain
      logger.debug("========= @current_country_code STEP 1: #{@current_country_code}")
    else
      @current_country_code = @current_selected_pro.country_code
      logger.debug("========= @current_country_code STEP 2: #{@current_country_code}")
    end
  end
  
  def require_selected_practitioner
    unless pro_logged_in?
      get_selected_practitioner
      #otherwise ask the client to select a practitioner
      if @current_selected_pro.nil?
        respond_to do |format|
          format.json do
            flash[:error] = I18n.t(:flash_error_session_not_selected_pro) 
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
