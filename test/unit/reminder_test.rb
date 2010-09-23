require File.dirname(__FILE__) + '/../test_helper'

class ReminderTest < ActiveSupport::TestCase
  def test_need_sending
    pro = Factory(:practitioner)
    Time.zone = pro.timezone

    booking_needs_sending = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => -30))
    assert_equal 1, booking_needs_sending.reminders.size

    booking_does_not_need_sending = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => 30))
    assert_equal 1, booking_does_not_need_sending.reminders.size

    reminders_need_sending = Reminder.need_sending
    
    assert_equal 1, reminders_need_sending.size
  end
end
