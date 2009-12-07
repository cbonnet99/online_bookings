class Booking < ActiveRecord::Base
  belongs_to :practitioner
  belongs_to :client
  attr_accessible :starts_at, :ends_at, :client_id
end
