class JsonUtils
  
  def self.scrub_undefined(hash)
    hash.each do |k,v|
      hash.delete(k) if v.nil? || v == "" || v == "undefined"
    end
    hash
  end
  
  def self.decode(json)
    hash = ActiveSupport::JSON.decode(json)
    scrub_undefined(hash)
  end
end