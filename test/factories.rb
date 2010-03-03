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
end

Factory.define :relation do |b|
  b.association :client
  b.association :practitioner
end

Factory.define :booking do |b|
  b.association :client
  b.association :practitioner
  b.name {|b| b.client.name}
  b.starts_at Time.now.tomorrow.beginning_of_day.advance(:hours=>9)
  b.ends_at Time.now.tomorrow.beginning_of_day.advance(:hours=>10)
end
