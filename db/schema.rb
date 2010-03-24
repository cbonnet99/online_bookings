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

ActiveRecord::Schema.define(:version => 20100324041718) do

  create_table "bookings", :force => true do |t|
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string   "name"
    t.integer  "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "practitioner_id"
    t.text     "comment"
    t.string   "booking_type"
    t.string   "confirmation_code"
    t.string   "state"
    t.datetime "pro_reminder_sent_at"
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

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

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
    t.string   "working_days",                    :limit => 20
    t.string   "working_hours"
    t.string   "bookings_publish_code"
    t.string   "phone"
    t.boolean  "reminder_night_before"
    t.integer  "no_cancellation_period_in_hours"
    t.string   "country_code"
    t.boolean  "invite_on_client_book",                         :default => true
    t.boolean  "invite_on_pro_book",                            :default => true
    t.string   "own_time_label"
  end

  create_table "relations", :force => true do |t|
    t.integer  "client_id"
    t.integer  "practitioner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.string   "subject"
    t.string   "email_type"
    t.integer  "delay_mins"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "practitioner_id"
    t.integer  "client_id"
    t.integer  "booking_id"
  end

end
