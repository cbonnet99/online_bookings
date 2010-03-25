# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

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

  def use_country_select
    if APP_CONFIG[:show_countries]
      content_for(:country_select) {  "Country:" + localized_country_select_tag(:current_country_code, @current_country_code, [:nz, :fr] )}
      content_for(:js_country_select) {javascript_include_tag("/country_select.js")}
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
