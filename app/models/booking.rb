class Booking < ActiveRecord::Base
  attr_accessible :starts_at, :ends_at, :client_id
end
