class Country < ActiveRecord::Base
  def self.default_country
    Country.all.select{|c| c.is_default?}.first
  end
end
