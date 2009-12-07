Factory.define :client do |f|
  # f.sequence(:first_name) {|n| "User#{n}"}
  # f.last_name "Name"
  f.password "foobar"
  f.password_confirmation { |u| u.password }
  f.sequence(:email) { |n| "foo#{n}@example.com" }
end
