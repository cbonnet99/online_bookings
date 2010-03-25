class BookingType < ActiveRecord::Base
  belongs_to :practitioner
  has_many :bookings
end
