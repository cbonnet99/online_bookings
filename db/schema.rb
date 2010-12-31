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

ActiveRecord::Schema.define(:version => 20101231103717) do

  create_table "booking_types", :force => true do |t|
    t.string   "title"
    t.integer  "duration_mins"
    t.integer  "practitioner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_default"
  end

  create_table "bookings", :force => true do |t|
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string   "name"
    t.integer  "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "practitioner_id"
    t.text     "comment"
    t.string   "confirmation_code"
    t.string   "state"
    t.datetime "pro_reminder_sent_at"
    t.integer  "booking_type_id"
    t.boolean  "prep_before",          :default => false
    t.integer  "prep_time_mins",       :default => 0
    t.datetime "confirmed_at"
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
    t.integer  "country_id"
  end

  create_table "countries", :force => true do |t|
    t.string   "country_code",                 :limit => 3
    t.boolean  "is_default",                                :default => false
    t.string   "locale",                       :limit => 3
    t.string   "mobile_phone_prefixes_list"
    t.string   "landline_phone_prefixes_list"
    t.string   "name"
    t.string   "timezones"
    t.text     "sample_first_names"
    t.text     "sample_last_names"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "demo_first_name"
    t.string   "demo_last_name"
    t.string   "demo_phone"
    t.string   "demo_email"
    t.string   "demo_password"
    t.string   "time_slots"
    t.integer  "default_start_time1"
    t.integer  "default_end_time1"
    t.integer  "default_start_time2"
    t.integer  "default_end_time2"
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

  create_table "extra_non_working_days", :force => true do |t|
    t.date     "day_date"
    t.integer  "practitioner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "extra_working_days", :force => true do |t|
    t.date     "day_date"
    t.integer  "practitioner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "extra_working_days", ["practitioner_id"], :name => "index_extra_working_days_on_practitioner_id"

  create_table "payment_plans", :force => true do |t|
    t.integer  "amount"
    t.string   "title"
    t.text     "description"
    t.integer  "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sms_credit",  :default => 0
  end

  create_table "payments", :force => true do |t|
    t.integer  "payment_plan_id"
    t.integer  "amount"
    t.string   "address1"
    t.string   "city"
    t.string   "zip"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "practitioner_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "ip_address"
    t.string   "card_type"
    t.date     "card_expires_on"
    t.string   "status"
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
    t.string   "working_days",                    :limit => 20
    t.string   "bookings_publish_code"
    t.boolean  "reminder_night_before"
    t.integer  "no_cancellation_period_in_hours"
    t.boolean  "invite_on_client_book",                         :default => true
    t.boolean  "invite_on_pro_book",                            :default => true
    t.string   "own_time_label"
    t.boolean  "prep_before",                                   :default => false
    t.integer  "prep_time_mins",                                :default => 0
    t.string   "timezone"
    t.string   "state"
    t.integer  "country_id"
    t.string   "phone_prefix"
    t.string   "phone_suffix"
    t.boolean  "lunch_break"
    t.integer  "start_time1"
    t.integer  "end_time1"
    t.integer  "start_time2"
    t.integer  "end_time2"
    t.integer  "sms_credit",                                    :default => 0
  end

  create_table "relations", :force => true do |t|
    t.integer  "client_id"
    t.integer  "practitioner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reminders", :force => true do |t|
    t.integer  "booking_id"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "sending_at"
    t.string   "reminder_type"
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
