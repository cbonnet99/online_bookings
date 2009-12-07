require File.dirname(__FILE__) + '/../test_helper'

class BookingTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Booking.new.valid?
  end
end
