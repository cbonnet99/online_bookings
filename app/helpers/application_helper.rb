# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def link_for_locale(url, locale)
    protocol, uri = url.split("//")
    uri_bits = uri.split("/")
    host_bits = uri_bits[0].split(".")
    if host_bits.size < 3
      if host_bits.last == "localhost:3000" && I18n.available_locales.include?(host_bits.first.to_sym)
        host_bits[0] = locale.to_s
        host = host_bits.join(".")        
      else
        host = "#{locale}.#{host_bits.join('.')}"
      end
    else
      host_bits[0] = locale.to_s
      host = host_bits.join(".")
    end
    uri_bits[0] = host
    return "#{protocol}//#{uri_bits.join('/')}"
  end

  def simpler_time(time)
    minutes = time.strftime("%M")
    hours = time.strftime("%l")
    am_pm = time.strftime("%p")
    hours_separator = I18n.t(:hours_separator, :scope=>[:time])
    hours_marker = I18n.t(:hours_marker, :scope=>[:time])
    if minutes == "00"
      if hours_marker.blank?
        "#{hours}#{am_pm.downcase}"
      else
        "#{hours}#{hours_marker}"
      end
    else
      if hours_marker.blank?
        "#{hours}#{hours_separator}#{minutes}#{am_pm.downcase}"
      else
        "#{hours}#{hours_marker}#{minutes}"
      end
    end
  end

  def client_needs_help
    !@current_client.nil? && @current_client.bookings.size == 0
  end
  
  def selected_tab_classes(tab, expected)
    if tab == expected
      "link selected-tab"
    else
      "link"
    end
  end
  
  def current_step
    if @current_selected_pro.nil?
      edit_selected_practitioner_url
    else
      if cookies[:email].nil?
        lookup_form_url
      else
        if session[:client_id].nil?
          login_phone_url(:login => cookies[:email])
        else
          practitioner_url(@current_selected_pro)
        end
      end
    end
  end

	def javascript(*files)
		content_for(:js) { javascript_include_tag(*files) }
	end

	def stylesheet(*files)
		content_for(:css) { stylesheet_link_tag(*files) }
	end
  
  def use_calendar
    content_for :calendar do
    	javascript_include_tag 'jquery-weekcalendar/jquery.weekcalendar.js'
    end
    content_for :css do
      stylesheet_link_tag 'jquery.weekcalendar'
    end
  end
  
  def own_calendar?(pro, current_pro)
    !pro.nil? && !current_pro.nil? && current_pro == pro
  end
  
  def current_pro_client_options(current_pro)
    res = "<option value=''>#{current_pro.own_time_label}</option>"
    current_pro.clients_options.each do |name, id|
      res << "<option value='#{id}'>#{name}</option>"
    end
    return res
  end

  def current_pro_phone_prefixes_options(current_pro)
    country_phone_prefixes_options(current_pro.country, current_pro.phone_prefix)
  end

  def country_phone_prefixes_options(country, selected_value)
    return (country || Country.default_country).phone_prefixes_select(selected_value)
  end
  
  def current_pro_booking_type_options(current_pro)
    res = ""
    current_pro.booking_types.each do |bt|
      res << "<option value='#{bt.id}'"
      res << " selected='selected'" if bt.is_default?
      res << ">#{bt.title}</option>"
    end
    return res
  end
end
