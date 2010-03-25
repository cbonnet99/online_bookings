class BookingType < ActiveRecord::Base
  belongs_to :practitioner
  has_many :bookings
  
  validates_presence_of :title, :duration_mins
  
end
