require File.dirname(__FILE__) + '/../test_helper'

class ReminderTest < ActiveSupport::TestCase

  def test_to_gsm0338
    assert_equal "Nous avons ete a gouter pres du chateau", "Nous avons été à goûter près du chateau".to_gsm0338
  end

  def test_send_reminder_email
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner, :country => countries(:fr), :sms_credit => 0)
    b = Factory(:booking, :practitioner => pro)
    r = b.create_reminder    
    assert_nil r.sent_at
    
    #SUT
    r.send!
    
    r.reload
    assert_not_nil r.sent_at
    assert_equal Reminder::TYPES[:email], r.reminder_type
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_send_reminder_sms
    pro = Factory(:practitioner, :country => countries(:fr), :sms_credit => 50 )
    b = Factory(:booking, :practitioner => pro)
    r = b.create_reminder
    assert_nil r.sent_at
    r.send_by_sms!
    r.reload
    assert_not_nil r.sent_at
    assert_equal Reminder::TYPES[:sms], r.reminder_type
    pro.reload
    assert_equal 49, pro.sms_credit
  end

  def test_send_reminder_sms_no_credit
    pro = Factory(:practitioner, :country => countries(:fr), :sms_credit => 0 )
    b = Factory(:booking, :practitioner => pro)
    r = b.create_reminder
    assert_nil r.sent_at
    r.send_by_sms!
    r.reload
    assert_not_nil r.sent_at
    assert_equal Reminder::TYPES[:email], r.reminder_type
  end



  def test_need_sending
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    
    booking_needs_sending = Factory(:booking, :starts_str => Booking.starts_str_builder(date_within_24_hours))
    booking_needs_sending.end_grace_period!
    assert_equal 1, booking_needs_sending.reminders.size

    booking_does_not_need_sending = Factory(:booking, :starts_str => Booking.starts_str_builder(date_after_24_hours))
    booking_does_not_need_sending.end_grace_period!
    assert_equal 1, booking_does_not_need_sending.reminders.size

    reminders_need_sending = Reminder.need_sending
    
    assert_equal 1, reminders_need_sending.size
  end
  
  def test_sent_by_email
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner)
    booking = Factory(:booking, :practitioner => pro)
    booking.end_grace_period!
    assert_equal 1, booking.reminders.size
    last_reminder = booking.reminders.last
    assert_nil last_reminder.sent_at    
    local_time_for_pro = Time.now.in_time_zone(pro.timezone)
    
    #SUT
    last_reminder.send_by_email!
    
    #Assertions
    assert_equal 1, ActionMailer::Base.deliveries.size
    Time.zone = pro.timezone
    last_reminder.reload
    assert_in_delta local_time_for_pro, last_reminder.sent_at, 1
  end
    
  def test_sent_by_email_for_test_user
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner, :state => "test_user", :email => "cyr@test.com" )
    self_client = Factory(:client, :email  =>  pro.email)
    
    booking = Factory(:booking, :practitioner => pro)
    booking_with_self = Factory(:booking, :practitioner => pro, :client => self_client, :client_email => self_client.email)
    
    booking.end_grace_period!
    booking_with_self.end_grace_period!
    
    assert_equal 1, booking_with_self.reminders.size    
    self_reminder = booking_with_self.reminders.last
    assert_nil self_reminder.sent_at    
    local_time_for_pro = Time.now.in_time_zone(pro.timezone)
    
    assert_equal 1, booking.reminders.size 
    other_reminder = booking.reminders.last
    
    #SUT
    self_reminder.send_by_email!
    other_reminder.send_by_email!
    
    #Assertions
    assert_equal 1, ActionMailer::Base.deliveries.size, "Only the reminder to self should have generated an email"
    Time.zone = pro.timezone
    self_reminder.reload
    assert_not_nil self_reminder.sent_at
    assert_in_delta local_time_for_pro, self_reminder.sent_at, 1
    
    other_reminder.reload
    assert_not_nil other_reminder.sent_at, "Even though no email was sent, the reminder should be marked as sent"
    
  end
    
end
