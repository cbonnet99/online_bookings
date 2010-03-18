class AddProToUserEmails < ActiveRecord::Migration
  def self.up
    add_column :user_emails, :practitioner_id, :integer
    add_column :user_emails, :client_id, :integer
  end

  def self.down
    remove_column :user_emails, :client_id
    remove_column :user_emails, :practitioner_id
  end
end
