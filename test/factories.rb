Factory.define :booking_type do |bt|
  bt.association :practitioner
  bt.duration_mins 60
  bt.title "Session"
  bt.is_default false
end
Factory.define :user_email do |e|
  e.association :client
  e.association :practitioner
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
end

Factory.define :practitioner do |f|
  # f.sequence(:first_name) {|n| "User#{n}"}
  # f.last_name "Name"
  f.first_name "John"
  f.last_name "Foo"
  f.working_hours "8-18"
  f.working_days "4,5"
  f.password "foobar"
  f.phone "021-234234324"
  f.no_cancellation_period_in_hours 24
  f.password_confirmation { |u| u.password }
  f.sequence(:email) { |n| "foo#{n}@example.com" }
  f.timezone "Wellington"
  f.test_user false
  f.trial false
end

Factory.define :relation do |b|
  b.association :client
  b.association :practitioner
end

Factory.define :booking do |b|
  b.association :client
  b.association :practitioner
  b.name {|b| b.client.try(:name) || "Own time"}
  b.starts_at Time.now.beginning_of_day.advance(:hours=>9)
  b.ends_at Time.now.beginning_of_day.advance(:hours=>10)
end

Factory.define :extra_working_day do |b|
  b.association :practitioner
  b.day_date 2.days.from_now
end

Factory.define :extra_non_working_day do |b|
  b.association :practitioner
  b.day_date 3.days.from_now
end