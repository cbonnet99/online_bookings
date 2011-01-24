class JsonUtils
  
  def self.remove_timezone(hash)
    unless hash.nil?
      hash.each do |k,v|
        if v.is_a?(ActiveSupport::TimeWithZone) || v.is_a?(DateTime)
          v = v.to_s
        end
        if v.is_a?(String)
          md = v.match(/.+(\d\d:\d\d:\d\d)/)
          if md
            hash[k] = md[0]
          end
        end
      end
    end
  end
  
  def self.scrub_undefined(hash)
    unless hash.nil?
      hash.each do |k,v|
        hash.delete(k) if v.nil? || v == "" || v == "undefined"
      end
      hash
    end
  end
  
  def self.decode(json)
    hash = ActiveSupport::JSON.decode(json)
    scrub_undefined(hash)
  end
end