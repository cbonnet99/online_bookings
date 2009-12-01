class WeeklyCalendar::Builder
  include ::ActionView::Helpers::TagHelper

  def initialize(objects, template, options, start_date, end_date)
    raise ArgumentError, "WeeklyBuilder expects an Array but found a #{objects.inspect}" unless objects.is_a? Array
    @objects, @template, @options, @start_date, @end_date = objects, template, options, start_date, end_date
  end
    
  def week(options = {})    
    hours = ["8am","8.30am","9am","9.30am","10am","10.30am","11am","11.30am","12pm","12.30pm","1pm","1.30pm","2pm","2.30pm","3pm","3.30pm","4pm","4.30pm","5pm","5.30pm","6pm"]
    header_row = "header_row"
    day_row = "day_row"
    grid = "grid"
    start_hour = 8
    end_hour = 18

    concat(tag("div", :id => "hours"))
      concat(content_tag("div", "", :id => "placeholder"))
        for hour in hours
          concat(content_tag("div", "<b>#{hour}</b>", :class => "hour"))
        end
      concat("</div>")      

    concat(tag("div", :id => "days"))
      concat(tag("div", :id => header_row))
        for day in @start_date..@end_date        
          concat(tag("div", :class => "header_box"))
          concat(content_tag("b", day.strftime('%A')))
          concat(tag("br"))
          concat(day.strftime('%d %B'))
          concat("</div>")
        end
      concat("</div>")

    
      
      concat(tag("div", :id => grid))
        for hour in hours 
          # for event in @objects
            for day in @start_date..@end_date
              concat(tag("div", :class => "slot", :open => true))
              concat("</div>")
              # if event.starts_at.strftime('%j').to_s == day.strftime('%j').to_s 
              #  if event.starts_at.strftime('%H').to_i >= start_hour and event.ends_at.strftime('%H').to_i <= end_hour
              #     concat(tag("div", :class => "booking", :style =>"left:#{left(event.starts_at,options[:business_hours])}px;width:#{width(event.starts_at,event.ends_at)}px;", :onclick => "location.href='/events/#{event.id}';"))
              #       truncate = truncate_width(width(event.starts_at,event.ends_at))
              #       yield(event,truncate)
              #     concat("</div>")
              #   end
              # end
            end
          # end
        end
      concat("</div>")
    concat("</div>")
  end
  
  private
  
    def concat(tag)
      @template.concat(tag)
    end

    def left(starts_at,business_hours)
      if business_hours == "true" or business_hours.blank?
        minutes = starts_at.strftime('%M').to_f * 1.25
        hour = starts_at.strftime('%H').to_f - 6
      else
        minutes = starts_at.strftime('%M').to_f * 1.25
        hour = starts_at.strftime('%H').to_f
      end
      left = (hour * 75) + minutes
    end

    def width(starts_at,ends_at)
      #example 3:30 - 5:30
      start_hours = starts_at.strftime('%H').to_i * 60 # 3 * 60 = 180
      start_minutes = starts_at.strftime('%M').to_i + start_hours # 30 + 180 = 210
      end_hours = ends_at.strftime('%H').to_i * 60 # 5 * 60 = 300
      end_minutes = ends_at.strftime('%M').to_i + end_hours # 30 + 300 = 330
      difference =  (end_minutes.to_i - start_minutes.to_i) * 1.25 # (330 - 180) = 150 * 1.25 = 187.5
    
      unless difference < 60
        width = difference - 12
      else
        width = 63 #default width (75px minus padding+border)
      end
    end
  
    def truncate_width(width)
      hours = width / 63
      truncate_width = 20 * hours
    end
    
end