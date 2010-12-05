class MoveCountryCodes < ActiveRecord::Migration
  def self.up
    add_column :clients, :country_id, :integer
    default_country = Country.default_country
    Client.all.each do |c|
      if c.country_code.blank?
        c.update_attribute(:country_id, default_country.id)
      else
        c.update_attribute(:country_id, Country.find_by_country_code(c.country_code).id)
      end
    end
    remove_column :clients, :country_code
    add_column :practitioners, :country_id, :integer
    default_country = Country.default_country
    Practitioner.all.each do |p|
      if p.country_code.blank?
        p.update_attribute(:country_id, default_country.id)
      else
        p.update_attribute(:country_id, Country.find_by_country_code(p.country_code).id)
      end
    end
    remove_column :practitioners, :country_code
  end

  def self.down
    add_column :clients, :country_code, :string, :limit => 3 
    default_country = Country.default_country
    Client.all.each do |c|
      if c.country_id.blank?
        c.update_attribute(:country_code, default_country.country_code)
      else
        c.update_attribute(:country_code, Country.find(c.country_id).country_code)
      end
    end
    remove_column :clients, :country_id
    add_column :practitioners, :country_code, :string, :limit => 3 
    default_country = Country.default_country
    Practitioner.all.each do |p|
      if p.country_id.blank?
        p.update_attribute(:country_code, default_country.country_code)
      else
        p.update_attribute(:country_code, Country.find(p.country_id).country_code)
      end
    end
    remove_column :practitioners, :country_id
  end
end
