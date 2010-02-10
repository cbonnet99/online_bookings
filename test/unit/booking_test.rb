require File.dirname(__FILE__) + '/../test_helper'

class BookingTest < ActiveSupport::TestCase  

  def test_create
    client = Factory(:client)
    pro = Factory(:practitioner)
    simple = Booking.create!(:name => "Joe Smith", :starts_at => 1.day.from_now,
     :ends_at => 1.day.from_now.advance(:hours => 1), :client => client, :practitioner => pro )
    assert_not_nil simple.confirmation_code
  end

  def test_need_reminders
    remind_me = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => -30))
    assert Booking.need_reminders.include?(remind_me)
  end

  def test_to_ics
    ics = bookings(:cyrille_sav).to_ics
    # puts "======= ics: #{ics}"
  end
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
