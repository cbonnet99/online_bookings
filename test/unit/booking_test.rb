require File.dirname(__FILE__) + '/../test_helper'

class BookingTest < ActiveSupport::TestCase

  def test_validation_times
    b = Factory.build(:booking, :starts_at => 3.hours.from_now, :ends_at => 2.hours.from_now)
    assert !b.valid?, "Booking should be invalid, because it ends before it starts"
    assert !b.errors.on(:starts_at).nil?
  end

  def test_validation_times_too_early
    pro_fr = Factory(:practitioner, :country => countries(:fr) )
    b = Factory.build(:booking, :starts_str => "2011/1/1 3:00:00", :practitioner => pro_fr)
    assert !b.valid?
    assert !b.errors.on(:starts_at).nil?
  end

  def test_validation_times_too_late
    pro_fr = Factory(:practitioner, :country => countries(:fr) )
    b = Factory.build(:booking, :starts_str => "2011/1/1 22:00:00", :ends_str => "2011/1/1 23:00:00", :practitioner => pro_fr)
    assert !b.valid?
    assert !b.errors.on(:starts_at).nil?
  end

  def test_url
    b = Factory(:booking)
    assert_not_nil b.url
  end

  def test_send_client_invite
    b = Factory(:booking)
    old_size = UserEmail.all.size
    b.send_client_invite
    assert_equal old_size+1, UserEmail.all.size
    assert_equal 1, b.user_emails.size
  end

  def test_end_grace_period
    pro_fr = Factory(:practitioner, :country => countries(:fr))
    b = Factory(:booking, :practitioner => pro_fr)
    old_size = UserEmail.all.size
    assert b.in_grace_period?
    b.end_grace_period!
    assert_equal old_size+1, UserEmail.all.size
    assert_equal 1, b.user_emails.size
    email_sent = b.user_emails.first
    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"].each do |str|
      assert_no_match Regexp.new(str), email_sent.subject, "Subject should be in French, but the word #{str} was found in: #{email_sent.subject}"
    end
  end

  def test_send_reminder_sms
    pro = Factory(:practitioner, :country => countries(:fr), :sms_credit => 50 )
    b = Factory(:booking, :practitioner => pro)
    r = b.create_reminder
    assert_nil r.sent_at
    b.send_reminder_sms!
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
    b.send_reminder_sms!
    r.reload
    assert_not_nil r.sent_at
    assert_equal Reminder::TYPES[:email], r.reminder_type
  end

  def test_sms_reminder_text_fr
    pro = Factory(:practitioner, :country => countries(:fr))
    b = Factory(:booking, :practitioner => pro)
    txt = b.sms_reminder_text
    assert_not_nil txt
    assert txt.size < Booking::SMS_MAX_SIZE
  end
  
  def test_sms_reminder_text_nz
    pro = Factory(:practitioner, :country => countries(:nz))
    b = Factory(:booking, :practitioner => pro)
    txt = b.sms_reminder_text
    assert_not_nil txt
    assert txt.size < Booking::SMS_MAX_SIZE
  end
  
  def test_endind_grace_period
    pro = Factory(:practitioner)
    booking_still_in_grace_period = Factory(:booking, :state => "in_grace_period", :created_at => 10.minutes.ago.in_time_zone(pro.timezone))
    booking_ending_grace_period = Factory(:booking, :state => "in_grace_period", :created_at => 2.hours.ago.in_time_zone(pro.timezone))
    assert_equal 1, Booking.ending_grace_period.size
  end    

  def test_start_date_str
    b = Factory(:booking)
    assert_no_match %r{00 CET}, b.start_date_str
  end

  def test_start_time_str
    pro_fr = Factory(:practitioner, :country => countries(:fr) )
    b = Factory(:booking, :practitioner  => pro_fr, :starts_str => "2011/1/1 15:00:00" )
    assert_match %r{15}, b.start_time_str, "3PM should show 15 in French"
  end

  def test_cancellation_text
    b = Factory(:booking)
    assert_not_nil b.cancellation_text
    name_regex = Regexp.new(b.practitioner.name)
    assert_match name_regex, b.cancellation_text
    assert_no_match %r{00 CET}, b.cancellation_text
  end

  def test_reminder_will_be_sent_at
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    
    booking = Factory(:booking, :practitioner => pro, :starts_str => starts_str_builder(2.days.from_now), :ends_str => ends_str_builder(2.days.from_now))
    booking.end_grace_period!
    assert_not_nil booking.reminder_will_be_sent_at, "A new booking in the future: a reminder should be sent"

    booking = Factory(:booking, :practitioner => pro, :starts_str => starts_str_builder(2.days.from_now), :ends_str => ends_str_builder(2.days.from_now))
    booking.confirm!
    assert_nil booking.reminder_will_be_sent_at, "An already confirmed booking in the future: a reminder should NOT be sent"
    
    booking = Factory(:booking, :practitioner => pro, :starts_str => starts_str_builder(2.days.ago), :ends_str => ends_str_builder(2.days.ago))
    booking.end_grace_period!
    booking.reminders.last.update_attribute(:sent_at, Time.zone.now)
    assert_nil booking.reminder_will_be_sent_at, "A new booking in the past: a reminder should already have been sent"
  end

  def test_reminder_was_sent_at
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    booking = Factory(:booking, :practitioner => pro, :starts_str => "#{starts_str_builder(2.days.ago)}", :ends_str => "#{ends_str_builder(2.days.ago)}")

    booking.end_grace_period!
    assert_equal 1, booking.reminders.size

    reminder = booking.last_reminder
    reminder.update_attribute(:sent_at, Time.now)
    reminder.reload

    booking.confirm!
    assert_equal 1, booking.reminders.size
    
    assert_not_nil booking.reminder_was_sent_at, "A confirmed booking in the past, with a reminder that was sent (sent at is not null): it should have a was sent at date"

    booking = Factory(:booking, :practitioner => pro, :starts_str => "#{starts_str_builder(2.days.from_now)}", :ends_str => "#{ends_str_builder(2.days.from_now)}")
    booking.end_grace_period!
    assert_nil booking.reminder_was_sent_at
  end

  def test_reminders
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    booking = Factory(:booking, :starts_str => starts_str_builder(2.days.from_now), :ends_str => ends_str_builder(2.days.from_now), :practitioner => pro)
    booking.end_grace_period!
    assert_equal 1, booking.reminders.size
  end

  def test_needs_warning
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    booking = Factory(:booking, :starts_str => starts_str_builder(date_within_24_hours), :state => "unconfirmed")
    assert booking.needs_warning?
    
    confirmed_booking = Factory(:booking, :starts_str => starts_str_builder(date_within_24_hours), :state => "confirmed")
    assert !confirmed_booking.needs_warning?
    
    unconfirmed_booking_in_far_future = Factory(:booking, :starts_str => starts_str_builder(2.days.from_now), :state => "unconfirmed")
    assert !unconfirmed_booking_in_far_future.needs_warning?
    
    past_booking = Factory(:booking, :starts_str => starts_str_builder(1.day.ago),  :state => "unconfirmed")
    assert !past_booking.needs_warning?
    
  end

  def test_destroy
    booking = Factory(:booking)
    booking.destroy
  end  

  def test_cancel_by_client
    booking = Factory(:booking)
    booking.end_grace_period!
    assert_equal 1, booking.reminders.size
    booking.client_cancel!
    booking.reload
    assert_equal 0, booking.reminders.size    
  end

  def test_cancel_by_pro
    booking = Factory(:booking)
    booking.end_grace_period!
    assert_equal 1, booking.reminders.size
    booking.pro_cancel!
    booking.reload
    assert_equal 0, booking.reminders.size    
  end

  def test_duration_mins
    booking = Factory(:booking)
    assert_equal 60, booking.duration_mins
  end

  def test_simple_time    
    starts_at = DateTime.strptime("1/1/2010 10:06 CEST", "%d/%m/%Y %H:%M %Z").in_time_zone("Paris")
    time = starts_at.simple_time
    assert_match "06", time
  end

  def test_js_args
    my_str = 18.hours.from_now.js_args
    assert_no_match %r{,0[1-9]+}, my_str, "There should be no leading 0 in JS date arguments, otherwise Javascript thinks it is an octal value"
  end

  def test_create
    client = Factory(:client)
    pro = Factory(:practitioner)
    date_str = 1.day.from_now.strftime("%Y-%m-%d")
    simple = Booking.create!(:name => "Joe Smith", :starts_str => "#{date_str} 10:00:00",
     :client => client, :practitioner => pro )
    assert_not_nil simple.confirmation_code
  end

  def test_to_ics
    ics = bookings(:cyrille_sav).to_ics
    # puts "======= ics: #{ics}"
  end
  
  def test_to_json_confirmed
    booking = Factory(:booking)
    booking.end_grace_period!
    assert booking.reminders.size > 0
    reminder = booking.reminders.first
    #let's pretend this reminder was sent, so that it won't be deleted on confirmation
    reminder.update_attribute(:sent_at, Time.now)
    #and let's pretend it was sent by email
    reminder.update_attribute(:reminder_type, Reminder::TYPES[:email])
    booking.confirm!

    json = booking.to_json
    assert_match %r{"confirmed_at":"(.*)"}, json
    assert booking.reminders.size > 0
    assert_match %r{"reminder_was_sent_at":"(.*)"}, json
    reminder = booking.reminders.first
    assert_equal "email", reminder.reminder_type
    assert_match %r{"reminder_was_sent_by":"email"}, json    
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
