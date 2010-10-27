require File.dirname(__FILE__) + '/../test_helper'

class BookingTest < ActiveSupport::TestCase  

  def test_reminder_will_be_sent_at
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    booking = Factory(:booking, :practitioner => pro, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now, :state => "new_booking")
    assert_not_nil booking.reminder_will_be_sent_at, "A new booking in the future: a reminder should be sent"

    booking = Factory(:booking, :practitioner => pro, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now, :state => "confirmed")
    assert_nil booking.reminder_will_be_sent_at, "An already confirmed booking in the future: a reminder should NOT be sent"

    booking = Factory(:booking, :practitioner => pro, :starts_at => 2.hours.ago, :ends_at => 3.hours.ago, :state => "new_booking")
    booking.reminders.last.update_attribute(:sent_at, Time.zone.now)
    assert_nil booking.reminder_will_be_sent_at, "A new booking in the past: a reminder should already have been sent"
  end

  def test_reminder_was_sent_at
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    booking = Factory(:booking, :practitioner => pro, :starts_at => 2.hours.ago, :ends_at => 3.hours.ago, :state => "confirmed")
    reminder = booking.last_reminder
    reminder.update_attribute(:sent_at, Time.now)
    reminder.reload
    assert_not_nil booking.reminder_was_sent_at, "A confirmed booking in the past, with a reminder that was sent (sent at is not null): it should have a was sent at date"

    booking = Factory(:booking, :practitioner => pro, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now, :state => "new_booking")
    assert_nil booking.reminder_was_sent_at
  end

  def test_reminders
    booking = Factory(:booking, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now, :state => "new_booking")
    reminders = booking.reminders
    assert_equal 1, reminders.size
  end

  def test_needs_warning
    booking = Factory(:booking, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now, :state => "new_booking")
    assert booking.needs_warning?

    booking = Factory(:booking, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now, :state => "confirmed")
    assert !booking.needs_warning?
    
    booking = Factory(:booking, :starts_at => 30.hours.from_now, :ends_at => 31.hours.from_now, :state => "new_booking")
    assert !booking.needs_warning?

    booking = Factory(:booking, :starts_at => 7.hours.ago, :ends_at => 3.hours.ago, :state => "new_booking")
    assert !booking.needs_warning?
    
  end

  def test_in_grace_period
    booking = Factory(:booking, :created_at => 20.minutes.ago, :state => "new_booking")
    assert booking.in_grace_period?

    booking = Factory(:booking, :created_at => 2.hours.ago)
    assert !booking.in_grace_period?
    
    booking = Factory(:booking, :created_at => 20.minutes.ago, :state => "confirmed")
    assert !booking.in_grace_period?
    
  end

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
  
  def test_to_json_confirmed
    booking = Factory(:booking, :confirmed_at  => 2.hours.ago)
    json = booking.to_json
    assert_match %r{"confirmed_at":"(.*)"}, json
    
  end
  
  def test_to_json_unconfirmed
    json = bookings(:cyrille_sav).to_json
    # puts "===== json: #{json}"
    assert_match %r{"id":}, json
    assert_match %r{"start":}, json
    assert_match %r{"end":}, json
    assert_match %r{"title":".*"}, json
    assert_match %r{"state":}, json
    assert_match %r{"needs_warning":}, json
    assert_match %r{"locked":}, json
    assert_match %r{"phone_prefix":}, json
    assert_match %r{"phone_suffix":}, json
    assert_match %r{"email":}, json
    assert_match %r{"readOnly":}, json
    assert_match %r{"client_name":}, json
    
    assert_no_match %r{"name":}, json
    assert_no_match %r{"booking":}, json
    assert_no_match %r{"confirmed_at":"(.*)"}, json
  end
end
