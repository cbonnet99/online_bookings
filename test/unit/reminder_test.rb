require File.dirname(__FILE__) + '/../test_helper'

class ReminderTest < ActiveSupport::TestCase
  def test_need_sending
    pro = Factory(:practitioner)
    Time.zone = pro.timezone

    booking_needs_sending = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => -30))
    booking_needs_sending.end_grace_period!
    assert_equal 1, booking_needs_sending.reminders.size

    booking_does_not_need_sending = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => 30))
    booking_does_not_need_sending.end_grace_period!
    assert_equal 1, booking_does_not_need_sending.reminders.size

    reminders_need_sending = Reminder.need_sending
    
    assert_equal 1, reminders_need_sending.size
  end
  
  def test_sent_by_email
    pro = Factory(:practitioner)
    booking = Factory(:booking, :practitioner => pro)
    booking.end_grace_period!
    assert_equal 1, booking.reminders.size
    last_reminder = booking.reminders.last
    assert_nil last_reminder.sent_at
    
    local_time_for_pro = Time.now.in_time_zone(pro.timezone)
    last_reminder.send_by_email!
    
    Time.zone = pro.timezone
    assert_in_delta local_time_for_pro, last_reminder.sent_at, 1
  end
  
end
