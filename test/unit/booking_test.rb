require File.dirname(__FILE__) + '/../test_helper'

class BookingTest < ActiveSupport::TestCase  

  def test_destroy
    booking = Factory(:booking)
    assert_equal 1, booking.reminders.size
    old_size = Reminder.all.size
    booking.destroy
    assert_equal old_size-1, Reminder.all.size
  end  

  def test_cancel
    booking = Factory(:booking)
    assert_equal 1, booking.reminders.size
    booking.cancel!
    booking.reload
    assert_equal 0, booking.reminders.size    
  end

  def test_duration_mins
    booking = Factory(:booking)
    assert_equal 60, booking.duration_mins
  end

  def test_simple_time
    booking = Factory(:booking)
    booking.starts_at.simple_time    
  end

  def test_js_args
    my_str = 18.hours.from_now.js_args
    assert_no_match %r{,0[1-9]+}, my_str, "There should be no leading 0 in JS date arguments, otherwise Javascript thinks it is an octal value"
  end

  def test_create
    client = Factory(:client)
    pro = Factory(:practitioner)
    simple = Booking.create!(:name => "Joe Smith", :starts_at => 1.day.from_now,
     :ends_at => 1.day.from_now.advance(:hours => 1), :client => client, :practitioner => pro )
    assert_not_nil simple.confirmation_code
  end

  # def test_need_reminders
  #   remind_me = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => -30), :name  => "In 1 day MINUS 30 mins")
  #   dont_remind_me = Factory(:booking, :starts_at => 1.day.from_now.advance(:hours => 2), :name  => "In 1 day PLUS 2 hours")
  #   my_reminders = Booking.need_reminders
  #   assert my_reminders.include?(remind_me)
  #   assert !my_reminders.include?(dont_remind_me)
  # end
  # 
  # def test_need_reminders_extended_cancellation
  #   pro = Factory(:practitioner, :no_cancellation_period_in_hours  => 48)
  #   remind_me = Factory(:booking, :starts_at => 2.days.from_now.advance(:minutes => -30), :practitioner => pro)
  #   dont_remind_me = Factory(:booking, :starts_at => 2.days.from_now.advance(:hours => 2), :practitioner => pro)
  #   my_reminders = Booking.need_reminders
  #   assert my_reminders.include?(remind_me)
  #   assert !my_reminders.include?(dont_remind_me)
  # end
  # 
  # def test_need_reminders_different_timezones
  #   pro = Factory(:practitioner, :timezone  => "Paris")
  #   remind_me = Factory(:booking, :starts_at => Time.zone.now.advance(:hours => 23), :practitioner => pro)
  #   dont_remind_me = Factory(:booking, :starts_at => Time.zone.now.advance(:hours => 26), :practitioner => pro)
  #   my_reminders = Booking.need_reminders
  #   assert my_reminders.include?(remind_me)
  #   assert !my_reminders.include?(dont_remind_me)
  # end

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
