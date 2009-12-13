require File.dirname(__FILE__) + '/../test_helper'

class BookingTest < ActiveSupport::TestCase  
  def test_to_json
    json = bookings(:cyrille_sav).to_json
    # puts "===== json: #{json}"
    assert_match %r{"id":}, json
    assert_match %r{"start":}, json
    assert_match %r{"end":}, json
    assert_match %r{"title":"Booked"}, json
    assert_match %r{"readOnly":}, json
    assert_no_match %r{"name":}, json
    assert_no_match %r{"booking":}, json
  end
end
