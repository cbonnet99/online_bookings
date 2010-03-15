class AddCountryToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :country_code, :string, :size => "2"
    execute("UPDATE practitioners SET country_code='NZ'")
  end

  def self.down
    remove_column :practitioners, :country_code
  end
end
