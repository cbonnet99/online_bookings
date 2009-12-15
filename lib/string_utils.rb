class StringUtils
  
  def self.fix_minutes(str)
    if !str.include?(":")
      return "#{str}:00"
    else
      return str
    end
  end
end