class AddCodeToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :bookings_publish_code, :string
  end

  def self.down
    remove_column :practitioners, :bookings_publish_code
  end
end
