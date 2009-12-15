class TimeUtils
  
  def self.round_previous_hour(str_time)
    if str_time.include?(":")
      return str_time.split(":").first
    else
      return str_time
    end
    
  end
  
  def self.round_next_hour(str_time)
    if str_time.include?(":")
      return (str_time.split(":").first.to_i+1).to_s
    else
      return str_time
    end
    
  end
  
  def self.fix_minutes(str)
    if !str.include?(":")
      return "#{str}:00"
    else
      return str
    end
  end
end