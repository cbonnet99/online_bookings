class ApplicationController < ActionController::Base
  include Authentication
  include ExceptionNotification::Notifiable
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  before_filter :get_selected_practitioner, :get_locales, :set_locale

  def get_current_country
    unless params[:country_code].blank?
      @current_country = Country.find_by_country_code(params[:country_code].upcase)
    end
    if @current_country.blank?
      @current_country = get_country_from_cookie
      if @current_country.nil?
        country_code = locate_current_user
        @current_country = Country.find_by_country_code(country_code.try(:upcase))
        if @current_country.nil?
          @current_country = Country.default_country
        end
      end
    end
  end

  def locate_current_user
    @client_ip = request.remote_ip
    geo = GeoIP.new("#{RAILS_ROOT}/geoip/GeoLiteCity.dat")
    logger.info("========= Locating user with IP address: #{@client_ip}")
    g = geo.city(@client_ip)
    if g.nil?
      logger.info("========= Locating user with IP address #{@client_ip}: found nothing")
      nil
    else
      logger.info("========= Located user with IP address: #{@client_ip} to country code: #{g[2]}")
      g[2]
    end
  end
  
  def get_country_from_cookie
    Country.find_by_country_code(cookies[:country_code].try(:upcase))
  end
    
  def get_locales
    @locales = I18n.available_locales
  end
  
  def set_locale
    @selected_locale = extract_locale_from_subdomain
    logger.debug("========= selected_locale from subdomain: #{@selected_locale}")
    if @selected_locale.nil? || !I18n.available_locales.include?(@selected_locale)
      country_code = locate_current_user
      @selected_locale = translate_country_code_to_locale(country_code)  
    end
    unless I18n.available_locales.include?(@selected_locale)
      @selected_locale = Country.default_locale
    end
    I18n.locale = @selected_locale
  end
  
  def translate_country_code_to_locale(country_code)
    country_code = country_code.try(:to_s) if country_code.is_a?(Symbol)
    country_code = country_code.try(:upcase) if country_code.is_a?(String)
    selected_country = Country.find_by_country_code(country_code)
    logger.debug("========= selected_country from subdomain: #{selected_country.try(:name)}")
    if selected_country.nil?
      selected_country = Country.default_country
    end
    return selected_country.locale
  end
  
  def extract_locale_from_subdomain
    request.url.split("//")[1].split(".").first.try(:downcase).try(:to_sym)
  end
  
  def get_phone_prefixes
    @country = current_pro.nil? ? @current_country : current_pro.country
    @mobile_prefixes = @country.try(:mobile_phone_prefixes) || Country.default_country.mobile_phone_prefixes
    @landline_prefixes = @country.try(:landline_phone_prefixes) || Country.default_country.landline_phone_prefixes
    @phone_prefixes = @mobile_prefixes + @landline_prefixes
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
  end  
end
