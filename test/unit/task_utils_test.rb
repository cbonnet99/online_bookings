require File.dirname(__FILE__) + '/../test_helper'

class TaskUtilsTest < ActiveSupport::TestCase

  def test_time_to_recreate_test_user
    france = countries(:fr)
    assert_equal 0, france.practitioners.test_user.size
    TaskUtils.time_to_recreate_test_user?(2, 5)
    assert_equal 1, france.practitioners.test_user.size
    french_test_user = france.practitioners.test_user.first
    TaskUtils.time_to_recreate_test_user?(2, 5)
    assert_equal 1, france.practitioners.test_user.size
    assert_equal french_test_user, france.practitioners.test_user.first, "The French test user should not have been recreated, since it was newly recreated"
    french_test_user.update_attribute(:created_at, 25.hours.ago)
    TaskUtils.time_to_recreate_test_user?(2, 5)
    assert_equal 1, france.practitioners.test_user.size
    assert_not_equal french_test_user, france.practitioners.test_user.first, "The French test user should have been recreated, since it was old"
  end

  def test_end_bookings_grace_period
    old_size = UserEmail.all.size
    pro = Factory(:practitioner)
    booking_still_in_grace_period = Factory(:booking, :state => "in_grace_period", :practitioner => pro,  :created_at => 10.minutes.ago.in_time_zone(pro.timezone))
    booking_ending_grace_period = Factory(:booking, :state => "in_grace_period", :practitioner => pro, :created_at => 2.hours.ago.in_time_zone(pro.timezone))
    
    TaskUtils.end_bookings_grace_period
    
    assert_equal old_size+1, UserEmail.all.size, "1 email should have been sent to the client with an invite"

    booking_still_in_grace_period.reload
    assert booking_still_in_grace_period.in_grace_period?
    assert_equal 0, booking_still_in_grace_period.reminders.size

    booking_ending_grace_period.reload
    assert booking_ending_grace_period.unconfirmed?
    assert_equal 1, booking_ending_grace_period.reminders.size
  end

  def test_create_sample_data
    bookings_size = Booking.all.size
    pro_size = Practitioner.all.size
    client_size = Client.all.size
    number_pros = 2
    number_clients = 3
    number_bookings = 10
    TaskUtils.create_sample_data(number_clients, number_bookings)
    assert_equal pro_size+number_pros, Practitioner.all.size, "2 pros should have been created"
    
    #bookings are in the past AND in the future
    total_number_bookings_per_pro = number_bookings * 2
    
    assert_equal bookings_size+(total_number_bookings_per_pro*number_pros), Booking.all.size
  end
  
  def test_send_reminders
    ActionMailer::Base.deliveries.clear
    
    pro = Factory(:practitioner)
    booking_remind_me = Factory(:booking, :practitioner => pro, :starts_str => starts_str_builder(date_within_24_hours))
    booking_remind_me.end_grace_period!
    assert_equal 1, booking_remind_me.reminders.size
    reminder = booking_remind_me.reminders.first
    assert_nil reminder.reminder_text
    
    booking_dont_remind_me = Factory(:booking, :practitioner => pro, :starts_str => starts_str_builder(date_after_24_hours))
    booking_dont_remind_me.end_grace_period!
    assert_equal 1, booking_dont_remind_me.reminders.size
    
    TaskUtils.send_reminders
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    reminder.reload
    assert_not_nil reminder.reminder_text
    
    ActionMailer::Base.deliveries.clear
    TaskUtils.send_reminders
    assert_equal 0, ActionMailer::Base.deliveries.size
    
  end
  
  def test_send_pro_reminders
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner, :reminder_night_before => true)
    remind_me = Factory(:booking, :starts_str => starts_str_builder(1.day.from_now), :practitioner_id => pro.id)
    dont_remind_me_too_late = Factory(:booking, :starts_str => starts_str_builder(2.days.from_now), :practitioner_id => pro.id)
    dont_remind_me_already_sent = Factory(:booking, :starts_str => starts_str_builder(1.day.from_now), :pro_reminder_sent_at => Time.now, :practitioner_id => pro.id)
    
    TaskUtils.send_pro_reminders
    
    assert_equal 1, ActionMailer::Base.deliveries.size

    ActionMailer::Base.deliveries.clear
    TaskUtils.send_pro_reminders
    assert_equal 0, ActionMailer::Base.deliveries.size
    
  end
  
end