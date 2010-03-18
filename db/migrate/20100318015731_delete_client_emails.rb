class DeleteClientEmails < ActiveRecord::Migration
  def self.up
    drop_table :client_emails
  end

  def self.down
    create_table :client_emails do |t|
      t.integer :client_id
      t.string :email_type
      t.datetime :sent_at

      t.timestamps
    end
  end
end
