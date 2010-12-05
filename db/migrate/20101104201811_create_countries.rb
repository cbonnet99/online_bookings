class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.string :country_code, :limit => 3 
      t.boolean :is_default, :default => false 
      t.string :locale, :limit => 3
      t.string :mobile_phone_prefixes_list
      t.string :landline_phone_prefixes_list
      t.text :sample_first_names
      t.text :sample_last_names
      t.string :name
      t.string :timezones
      t.timestamps
    end
  end

  def self.down
    drop_table :countries
  end
end
