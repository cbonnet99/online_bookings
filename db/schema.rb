# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091210090450) do

  create_table "bookings", :force => true do |t|
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string   "name"
    t.integer  "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "practitioner_id"
  end

  create_table "client_emails", :force => true do |t|
    t.integer  "client_id"
    t.string   "email_type"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clients", :force => true do |t|
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.string   "question",      :limit => 500
    t.string   "answer"
    t.string   "string"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone_prefix",  :limit => 3
    t.string   "phone_suffix",  :limit => 10
    t.string   "reset_code",    :limit => 40
    t.string   "first_name"
    t.string   "last_name"
  end

  create_table "practitioners", :force => true do |t|
    t.string   "username"
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "permalink"
    t.string   "biz_hours_start", :limit => 5
    t.string   "biz_hours_end",   :limit => 5
    t.string   "working_days",    :limit => 20
  end

end
