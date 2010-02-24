# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def javascript(*files)
		content_for(:js) { javascript_include_tag(*files) }
	end

	def stylesheet(*files)
		content_for(:css) { stylesheet_link_tag(*files) }
	end
  
  def use_calendar
    content_for :calendar do
    	javascript_include_tag 'jquery-weekcalendar/jquery.weekcalendar'
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
      res << "<option value='#{id}'>#{name}</option"
    end
    return res
  end
end
