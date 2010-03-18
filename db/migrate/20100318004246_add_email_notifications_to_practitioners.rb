class AddEmailNotificationsToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :invite_on_client_book, :boolean, :default => true
    add_column :practitioners, :invite_on_pro_book, :boolean, :default => true
    execute "UPDATE practitioners SET invite_on_client_book=true"
    execute "UPDATE practitioners SET invite_on_pro_book=true"
  end

  def self.down
    remove_column :practitioners, :invite_on_client_book
    remove_column :practitioners, :invite_on_pro_book
  end
end
