Factory.define :country do |c|
  c.is_default false
  c.country_code "FR"
  c.locale "FR"
  c.mobile_phone_prefixes_list "06,07"
  c.landline_phone_prefixes_list "01,02,03,04,05,08,09"
end

Factory.define :booking_type do |bt|
  bt.association :practitioner
  bt.duration_mins 60
  bt.title "Session"
  bt.is_default false
end
Factory.define :user_email do |e|
  e.association :client
  e.practitioner {|a| a.association(:client).practitioner}
  e.association :booking
  e.sequence(:to) { |n| "foo#{n}@example.com" }
  e.from "admin@colibriapp.com"
  e.subject "A nice email from us"
end

Factory.define :client do |f|
  f.sequence(:first_name) {|n| "User#{n}"}
  f.last_name "Name"
  f.password "foobar"
  f.password_confirmation { |u| u.password }
  f.sequence(:email) { |n| "foo#{n}@example.com" }
  f.association :country
  f.association :practitioner
end

Factory.define :practitioner do |f|
  # f.sequence(:first_name) {|n| "User#{n}"}
  # f.last_name "Name"
  f.first_name "John"
  f.last_name "Foo"
  f.lunch_break false
  f.start_time1 8
  f.end_time1 18
  f.working_days "4,5"
  f.password "foobar"
  f.phone_prefix "021"
  f.phone_suffix"234234324"
  f.no_cancellation_period_in_hours 24
  f.password_confirmation { |u| u.password }
  f.sequence(:email) { |n| "foo#{n}@example.com" }
  f.timezone "Wellington"
  f.state "active"
  f.association :country
  f.invite_on_pro_book true
end

Factory.define :booking do |b|
  b.association :client
  b.association :practitioner
  b.name {|b| b.client.try(:name) || "Own time"}
  t = Time.now.end_of_week.advance(:day => 1)
  day_str = t.strftime("%Y-%m-%d")
  b.starts_str "#{day_str} 10:00:00"
  b.sequence(:client_email) { |n| "foo#{n}@test.com" }  
  b.state "in_grace_period"
end

Factory.define :extra_working_day do |b|
  b.association :practitioner
  b.day_date 2.days.from_now
end

Factory.define :extra_non_working_day do |b|
  b.association :practitioner
  b.day_date 3.days.from_now
end
Factory.define :reminder do |r|
  r.association :booking
end
