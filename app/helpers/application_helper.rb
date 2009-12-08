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
    	javascript_include_tag 'jquery.weekcalendar'
    end
  end
end
