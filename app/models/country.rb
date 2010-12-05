class Country < ActiveRecord::Base
  
  has_many :clients
  has_many :practitioners
  
  def self.default_country
    Country.all.select{|c| c.is_default?}.first
  end
  
  def self.available_countries
    Country.find(:all, :order => "is_default desc, name")
  end
  
  def self.available_country_codes
    Country.available_countries.map(&:country_code)
  end
  
  def mobile_phone_prefixes
    mobile_phone_prefixes_list.split(",").map(&:strip)
  end

  def landline_phone_prefixes
    landline_phone_prefixes_list.split(",").map(&:strip)
  end
  
  def lowercase_locale
    locale.downcase
  end

end
