require File.dirname(__FILE__) + '/../test_helper'

class TaskUtilsTest < ActiveSupport::TestCase

  def test_create_sample_data
    bookings_size = Booking.all.size
    pro_size = Practitioner.all.size
    client_size = Client.all.size
    TaskUtils.create_sample_data
    assert_equal pro_size+2, Practitioner.all.size, "2 pros should have been created"
    assert_equal bookings_size+600, Booking.all.size, "300 appointments should have been created"
  end
  
  def test_send_reminders
    ActionMailer::Base.deliveries.clear
    booking_remind_me = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => -30))
    
    booking_dont_remind_me = Factory(:booking, :state => "reminder_sent", :starts_at => 1.day.from_now.advance(:minutes => 30))
    
    TaskUtils.send_reminders
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    
    ActionMailer::Base.deliveries.clear
    TaskUtils.send_reminders
    assert_equal 0, ActionMailer::Base.deliveries.size
    
  end
  
  def test_send_pro_reminders
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner, :reminder_night_before => true)
    remind_me = Factory(:booking, :starts_at => 1.day.from_now, :practitioner_id => pro.id)
    dont_remind_me_too_late = Factory(:booking, :starts_at => 2.days.from_now, :practitioner_id => pro.id)
    dont_remind_me_already_sent = Factory(:booking, :starts_at => 1.day.from_now, :pro_reminder_sent_at => Time.now, :practitioner_id => pro.id)
    
    TaskUtils.send_pro_reminders
    
    assert_equal 1, ActionMailer::Base.deliveries.size

    ActionMailer::Base.deliveries.clear
    TaskUtils.send_pro_reminders
    assert_equal 0, ActionMailer::Base.deliveries.size
    
  end
  
end