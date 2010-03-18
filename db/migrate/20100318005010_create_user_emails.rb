class CreateUserEmails < ActiveRecord::Migration
  def self.up
    create_table :user_emails do |t|
      t.string :from
      t.string :to
      t.string :subject
      t.string :email_type
      t.integer :delay_mins
      t.datetime :sent_at

      t.timestamps
    end
  end

  def self.down
    drop_table :user_emails
  end
end
