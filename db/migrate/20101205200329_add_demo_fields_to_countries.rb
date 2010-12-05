class AddDemoFieldsToCountries < ActiveRecord::Migration
  def self.up
    add_column :countries, :demo_first_name, :string
    add_column :countries, :demo_last_name, :string
    add_column :countries, :demo_phone, :string
    add_column :countries, :demo_email, :string
    add_column :countries, :demo_password, :string
  end

  def self.down
    remove_column :countries, :demo_password
    remove_column :countries, :demo_email
    remove_column :countries, :demo_phone
    remove_column :countries, :demo_last_name
    remove_column :countries, :demo_first_name
  end
end
