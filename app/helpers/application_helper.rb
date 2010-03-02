# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def selected_tab_classes(tab, expected)
    if tab == expected
      "link selected"
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
          practitioner_url(@current_selected_pro, :tab => "calendar")
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
    res = ""
    current_pro.clients_options.each do |name, id|
      res << "<option value='#{id}'>#{name}</option>"
    end
    return res
  end
end
