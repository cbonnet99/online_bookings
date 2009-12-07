class CreateClientEmails < ActiveRecord::Migration
  def self.up
    create_table :client_emails do |t|
      t.integer :client_id
      t.string :email_type
      t.datetime :sent_at

      t.timestamps
    end
  end

  def self.down
    drop_table :client_emails
  end
end
