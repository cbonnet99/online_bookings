class ApplicationController < ActionController::Base
  include Authentication
  include ExceptionNotification::Notifiable
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  before_filter :get_selected_practitioner
  before_filter :set_locale

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
  
  def default_country
    return Country.default_country
  end
  
  def set_locale
    selected_locale = extract_locale_from_subdomain
    logger.debug("========= selected_locale from subdomain: #{selected_locale}")
    if selected_locale.nil?
      country_code = locate_current_user
      selected_locale = translate_country_code_to_locale(country_code)  
    end
    I18n.locale = selected_locale.downcase unless selected_locale.nil?
  end
  
  def translate_country_code_to_locale(country_code)
    country_code = country_code.try(:to_s) if country_code.is_a?(Symbol)
    country_code = country_code.try(:upcase) if country_code.is_a?(String)
    selected_country = Country.find_by_country_code(country_code)
    logger.debug("========= selected_country from subdomain: #{selected_country}")
    if selected_country.nil?
      selected_country = Country.default_country
    end
    return selected_country.locale
  end
  
  def extract_locale_from_subdomain
    country_code = request.subdomains.first.try(:downcase).try(:to_sym)
    if country_code.blank?
      logger.debug("++++++++ Locating user")
      country_code = locate_current_user
    end      
    logger.debug("========= country_code from subdomain: #{country_code}")
    cookies[:country_code] = country_code.try(:to_s) unless country_code.blank?
    parsed_locale = translate_country_code_to_locale(country_code)
    (I18n.available_locales.include? parsed_locale.try(:downcase).try(:to_sym)) ? parsed_locale  : nil
  end
  
  def get_country_code_from_subdomain
    res = request.subdomains.first.try(:upcase)
    if res.blank? || !Country.available_country_codes.include?(res)
      res = locate_current_user
    end
    res = Country.default_country.country_code if !Country.available_country_codes.include?(res)
    res
  end
  
  def get_phone_prefixes
    @country = Country.find_by_country_code(cookies[:country_code].try(:upcase))
    @mobile_prefixes = @country.try(:mobile_phone_prefixes) || Country.default_country.mobile_phone_prefixes
    @landline_prefixes = @country.try(:landline_phone_prefixes) || Country.default_country.landline_phone_prefixes
    @phone_prefixes = @mobile_prefixes + @landline_prefixes
  end
  
  def get_practitioners(country_code)
    country_code = @current_country_code if country_code.blank?    
    country_code = Country.default_country.country_code if country_code.blank?
    @country = Country.find_by_country_code(country_code)
    @practitioners = @country.try(:practitioners)
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
    else
      @current_country_code = @current_selected_pro.country.country_code
    end
    unless @current_country_code.blank?
      @current_country = Country.find_by_country_code(@current_country_code)
    end
  end  
end
