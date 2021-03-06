require File.dirname(__FILE__) + '/../test_helper'

class PractitionerTest < ActiveSupport::TestCase
  
  include ColibriExceptions
  
  fixtures :all

  def test_create
    pro = Factory(:practitioner, :first_name => "Cyrille", :last_name => "Bonnet")
    assert_equal "cyrille-bonnet", pro.permalink
  end

  def test_locale
    pro_nz = Factory(:practitioner, :country => countries(:nz))
    pro_fr = Factory(:practitioner, :country => countries(:fr))
    
    assert_equal "EN", pro_nz.locale
    assert_equal "FR", pro_fr.locale
  end

  def test_unique_permalinks
    pro = Factory(:practitioner, :first_name => "Tom", :last_name => "Jones")
    pro_identical = Factory(:practitioner, :first_name => "Tom", :last_name => "Jones")
    assert_not_equal pro.permalink, pro_identical.permalink
  end

  def test_phone_prefixes
    pro = Factory(:practitioner, :country => countries(:fr))
    assert_equal ["06", "07"], pro.mobile_phone_prefixes
    assert_equal ["01", "02", "03", "04", "05", "08", "09"], pro.landline_phone_prefixes

    pro = Factory(:practitioner, :country => countries(:nz))
    assert_equal ["021", "022", "027", "029"], pro.mobile_phone_prefixes
    assert_equal ["03", "04", "06", "07", "09"], pro.landline_phone_prefixes

  end

  def test_delete_sample_data
    pro = Factory(:practitioner, :state => "test_user", :country  => countries(:fr))
    pro.create_sample_data!
    pro.delete_sample_data!
  end
  
  def test_delete_sample_data_for_non_test_user
    pro = Factory(:practitioner, :state => "active", :country  => countries(:fr))
    client = Factory(:client, :practitioner => pro)
    assert_equal 1, pro.clients.size
    assert_raise(CantDeleteSampleDataOnNonTestProException) do
      pro.delete_sample_data!
    end
    pro.reload
    assert_equal 1, pro.clients.size
  end
  

  def test_create_sample_data_for_non_test_user
    pro = Factory(:practitioner, :state => "active", :country  => countries(:fr))
    assert_raise(CantCreateSampleDataOnNonTestProException){
      pro.create_sample_data!
    }
    
  end

  def test_create_sample_data
    old_reminders_size = Reminder.all.size
    old_bookings_size = Booking.all.size
    pro = Factory(:practitioner, :state => "test_user", :country  => countries(:fr))
    assert_equal 0, pro.bookings.size
    pro.create_sample_data!
    pro.reload
    assert_equal 6, pro.clients.size
    assert_equal 30, pro.bookings.size, "There should be 15 bookings in the past and 15 bookings in the future"
    bookings_in_the_past = pro.bookings.find(:all, :conditions => ["starts_at < ?", Time.now.in_time_zone(pro.timezone).advance(:hours => -2)])
    assert bookings_in_the_past.size > 0, "There should be at least one booking in the past"
    unconfirmed_bookings_in_the_past = bookings_in_the_past.select{|b| b.unconfirmed?}
    confirmed_bookings_in_the_past = bookings_in_the_past.select{|b| b.confirmed?}
    
    confirmed_bookings_in_the_past.each do |b|
      assert_equal 1, b.reminders.size, "There should be a reminder for confirmed past booking: #{b}"
      assert !b.confirmed_at.nil?, "Booking #{b} has no confirmed_at date"
      last_reminder = b.last_reminder
      assert_not_nil last_reminder
      assert_not_nil last_reminder.sent_at, "Reminder #{last_reminder} has not sent_at value"
      assert_not_nil last_reminder.reminder_type
      assert last_reminder.sent_at < Time.now
      assert last_reminder.sent_at < b.starts_at
      assert_not_nil last_reminder.sending_at
      assert last_reminder.sending_at < Time.now
      assert last_reminder.sending_at < b.starts_at      
      assert_not_nil last_reminder.reminder_type
    end
    
    unconfirmed_bookings_in_the_past.each do |b|      
      assert_equal 1, b.reminders.size, "There should be a reminder for unconfirmed past booking: #{b}"
      last_reminder = b.last_reminder
      assert_not_nil last_reminder.sending_at
      assert last_reminder.sending_at < Time.now
      assert last_reminder.sending_at < b.starts_at
      if !last_reminder.sent_at.nil?
        assert_not_nil last_reminder.reminder_type
      end
    end
    assert_not_nil pro.clients.find_by_email(pro.email), "A test client with the same email as the pro should have been created"

    confirmed_bookings_in_the_future = pro.bookings.find(:all, :conditions => ["starts_at > ? and state = ?", Time.now.in_time_zone(pro.timezone), "confirmed"])
    confirmed_bookings_in_the_future.each do |b|
      assert !b.confirmed_at.nil?, "Booking #{b} has no confirmed_at date"
      assert b.reminders.size > 0, "Booking #{b} should have a reminder"
      r = b.last_reminder
      assert_not_nil r.sent_at, "Booking #{b} reminder should have a sent_at. Reminder is: #{r}"
    end
    unconfirmed_bookings_in_the_future = pro.bookings.find(:all, :conditions => ["starts_at > ? and state = ?", Time.now.in_time_zone(pro.timezone), "unconfirmed"])    
    unconfirmed_bookings_in_the_future.each do |b|
      assert_equal 1, b.reminders.size, "A reminder should have been created for unconfirmed future booking: #{b}"
      reminder = b.last_reminder
    end
    
    invalid_reminders = Reminder.find_all_by_reminder_type(nil). select{|r| !r.sent_at.nil?}
    assert_equal 0, invalid_reminders.size, "Invalid reminders found: #{invalid_reminders.map(&:to_s).to_sentence}"
    pro.destroy
    
    assert_equal old_reminders_size, Reminder.all.size    
    assert_equal old_bookings_size, Booking.all.size
    
  end

  def test_working_days_as_numbers
    pro = Factory(:practitioner, :working_days => "1,2,3,4,5")
    assert_equal [1,2,3,4,5], pro.working_days_as_numbers
    pro = Factory(:practitioner, :working_days => "6,7")
    assert_equal [6,0], pro.working_days_as_numbers
  end

  def test_working_days_in_timeframe
    pro = Factory(:practitioner)
    assert_equal 2, pro.working_days_in_timeframe(Time.now.beginning_of_week, Time.now.end_of_week).size
  end
  
  def new_practitioner(attributes = {})
    attributes[:username] ||= 'foo'
    attributes[:email] ||= 'foo@example.com'
    attributes[:password] ||= 'abc123'
    attributes[:working_days] = "1,2,3,4,5"
    attributes[:state] = "active"
    attributes[:password_confirmation] ||= attributes[:password]
    practitioner = Practitioner.new(attributes)
    practitioner.valid? # run validations
    practitioner
  end
  
  def setup
    Practitioner.delete_all
  end

  def test_own_bookings_with_prep_times
    pro = Factory(:practitioner, :prep_before => false, :prep_time_mins => 30)
    booking = Factory(:booking, :practitioner => pro, :prep_before => false, :prep_time_mins => 30, :starts_str => Booking.starts_str_builder(2.days.from_now), :ends_str => Booking.ends_str_builder(2.days.from_now))
    #just in case we run these tests on a Sunday after 10PM, I'll take the end of next week...
    my_own_bookings = pro.own_bookings(Time.now.beginning_of_week, Time.now.next_week.end_of_week)
    assert my_own_bookings.include?(booking)
    assert !my_own_bookings.select{|b| b.title == "Prep time"}.blank? || !my_own_bookings.select{|b| b.title == "Préparation"}.blank?
  end

  # def test_own_bookings_with_own_time_no_prep_times
  #   pro = Factory(:practitioner, :prep_before => false, :prep_time_mins => 30)
  #   booking = Factory(:booking, :practitioner => pro, :client => nil, :prep_before => false, :prep_time_mins => 30, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now)
  #   my_own_bookings = pro.own_bookings
  #   assert my_own_bookings.include?(booking)
  #   assert my_own_bookings.select{|b| b.title == "Prep time"}.blank?, "There should be no prep times for bookings with no client (own time)"
  # end

  def test_client_bookings_with_prep_times
    client = Factory(:client)
    pro = Factory(:practitioner, :prep_before => false, :prep_time_mins => 30)
    booking = Factory(:booking, :practitioner => pro, :client => client, :prep_before => false, :prep_time_mins => 30, :starts_str => Booking.starts_str_builder(date_within_24_hours), :ends_str => Booking.ends_str_builder(date_within_24_hours))
    #just in case we run these tests on a Sunday after 10PM, I'll take the end of next week...
    my_bookings = pro.client_bookings(client, Time.now.beginning_of_week, Time.now.next_week.end_of_week)
    assert my_bookings.include?(booking)
    assert !my_bookings.select{|b| b.duration_mins == 30}.blank?    
  end

  def test_default_booking_length_in_timeslots
    pro = Factory(:practitioner)
    assert_equal 2, pro.default_booking_length_in_timeslots, "2 should be the default"    
    booking_type1 = Factory(:booking_type, :practitioner => pro, :duration_mins => 120)
    pro.reload
    assert_equal 4, pro.default_booking_length_in_timeslots
    booking_type2 = Factory(:booking_type, :practitioner => pro, :duration_mins => 90)
    pro.reload
    assert_equal 4, pro.default_booking_length_in_timeslots, "Only the default one count"    
  end

  def test_set_working_days
    pro = Factory(:practitioner, :working_days => nil, :working_day_monday => "1", :working_day_tuesday => "1",
                  :working_day_wednesday => "1", :working_day_thursday => "1", :working_day_friday => "1",
                  :working_day_saturday => "0", :working_day_sunday => "0")
    assert_equal "1,2,3,4,5", pro.working_days
  end

  def test_add_client_existing
    pro = Factory(:practitioner)
    client = Factory(:client)
    old_overall_size = Client.all.size
    old_size = pro.clients.size
        
    pro.add_clients(client.email, false, "", "")
    assert_equal old_overall_size+1, Client.all.size
    pro.reload
    assert_equal old_size+1, pro.clients.size
  end

  def test_add_client
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner)
    client = Factory(:client)
    old_size = Client.all.size
    
    pro.add_clients("cbonnet@test.com", true, "This is a test", "Cheers")
    assert_equal old_size+1, Client.all.size
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    new_email = ActionMailer::Base.deliveries.first
    assert_equal ["cbonnet@test.com"], new_email.to
    assert_equal [pro.email], new_email.from
    assert_match /Hello,/, new_email.body
  end
    
  def test_add_client_with_name
    ActionMailer::Base.deliveries.clear
    
    pro = Factory(:practitioner)
    client = Factory(:client)
    old_size = Client.all.size
    
    pro.add_clients("\"Cyrille Bonnet\" <cbonnet@test.com>", true, "This is a test", "Cheers")
    assert_equal old_size+1, Client.all.size
    new_client = Client.find_by_email("cbonnet@test.com")
    assert_equal "Cyrille Bonnet", new_client.name
    assert_equal 1, ActionMailer::Base.deliveries.size
    new_email = ActionMailer::Base.deliveries.first
    assert_equal ["cbonnet@test.com"], new_email.to
    assert_equal [pro.email], new_email.from
    assert_match /Dear Cyrille,/, new_email.body
  end
    
  def test_add_existing_client_with_name
    ActionMailer::Base.deliveries.clear
    
    pro = Factory(:practitioner)
    client = Factory(:client)
    old_name = client.name
    old_size = Client.all.size
    
    pro.add_clients("\"New Name\" <#{client.email}>", true, "This is a test", "Cheers")
    assert_equal old_size+1, Client.all.size
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    new_email = ActionMailer::Base.deliveries.first
    assert_match %r{Dear New,}, new_email.body    
  end
    
  def test_add_client_invalid_email
    pro = Factory(:practitioner)
    client = Factory(:client)
    old_size = Client.all.size
    
    assert_raise InvalidEmailsException do
      pro.add_clients("cbonnet", false, "", "")
    end    
  end
  
  def test_add_client_invalid_email_double
    pro = Factory(:practitioner)
    client = Factory(:client)
    old_size = Client.all.size
    
    begin
      pro.add_clients("cbonnet,eeee", false, "", "")
    rescue InvalidEmailsException => e
      assert_equal 2, e.message.gsub(/ et /, ",").split(",").size, "There should 2 invalid emails, but message was: #{e.message}"
    end
  end
  
  def test_need_reminders
    pro = Factory(:practitioner)
    remind_me = Factory(:booking, :starts_at => 1.day.from_now, :practitioner_id => pro.id)
    dont_remind_me_too_late = Factory(:booking, :starts_at => 2.days.from_now, :practitioner_id => pro.id)
    dont_remind_me_already_sent = Factory(:booking, :starts_at => 1.day.from_now, :pro_reminder_sent_at => Time.now, :practitioner_id => pro.id)
    
    all_pros_size = Practitioner.all.size
    assert Practitioner.need_reminders.size <= all_pros_size
  end
  
  def test_bookings_need_pro_reminder
    pro = Factory(:practitioner)
    close_future_str = 1.day.from_now.strftime("%Y-%m-%d")
    past_str = 1.day.ago.strftime("%Y-%m-%d")
    far_future_str = 2.days.from_now.strftime("%Y-%m-%d")
    remind_me = Factory(:booking, :starts_str => "#{close_future_str} 10:00:00", :practitioner_id => pro.id)
    dont_remind_me_already_passed = Factory(:booking, :starts_str =>"#{past_str} 10:00:00", :practitioner_id => pro.id)
    dont_remind_me_too_far_in_the_future = Factory(:booking, :starts_str => "#{far_future_str} 10:00:00", :practitioner_id => pro.id)
    dont_remind_me_already_sent = Factory(:booking, :starts_str => "#{close_future_str} 10:00:00", :pro_reminder_sent_at => Time.now, :practitioner_id => pro.id)
    
    assert_equal 1, pro.bookings.need_pro_reminder.size, "Bookings are: #{pro.bookings.need_pro_reminder.inspect}"
  end
  
  def test_clients_options
    megan = Factory(:practitioner, :working_days => "4,5")
    cyrille = Factory(:client, :practitioner => megan )
    k = Factory(:client, :practitioner => megan)
    opts = megan.clients_options
    assert_equal 2, opts.size
    assert_equal [cyrille.name, cyrille.id], opts.first
  end

  def test_all_bookings
    megan = Factory(:practitioner, :working_days => "1,2,3,4,5,6,7")
    Time.zone = megan.timezone
    cyrille = Factory(:client, :first_name => "Cyrille", :last_name => "Bonnet")
    k = Factory(:client, :first_name => "Ms", :last_name => "K")
    d1 = date_within_week
    booking1 = Factory(:booking, :client => cyrille, :practitioner => megan, :starts_str  => Booking.starts_str_builder(d1, 10),
    :ends_str => Booking.ends_str_builder(d1, 11))
    d2 = date_within_week
    booking2 = Factory(:booking, :client => k, :practitioner => megan, :starts_str  => Booking.starts_str_builder(d2, 11),
    :ends_str => Booking.ends_str_builder(d2, 12))
    booking_cancelled = Factory(:booking, :state => "cancelled_by_client",  :client => k, :practitioner => megan )
    megan_bookings = megan.all_bookings(cyrille, Time.zone.now.beginning_of_week.to_f, Time.zone.now.end_of_week.to_f)
    assert megan_bookings.is_a?(Enumerable)    
    assert_equal 2, megan_bookings.size, "Megan bookings seen by Cyrille are: #{megan_bookings.to_sentence}"
    cyrille_booking = megan_bookings.select{|b| b.is_a?(Booking) && b.client_id == cyrille.id}.first
    assert !cyrille_booking.read_only?, "Booking was: #{cyrille_booking.inspect}"
    k_booking = megan_bookings.select{|b| b.is_a?(Booking) && b.client_id == k.id}.first
    assert k_booking.read_only?
  end
  
  def test_works_weekends
    megan = Factory(:practitioner, :working_days => "4,5")
    assert !megan.works_weekends?
    sav = Factory(:practitioner, :working_days => "4,5,6")
    assert sav.works_weekends?
    joe = Factory(:practitioner, :working_days => "4,5,7")
    assert joe.works_weekends?
  end
  
  def test_bookings_for_non_working_days
    megan = Factory(:practitioner, :working_days => "4,5")
    bookings = megan.bookings_for_non_working_days(Time.now.beginning_of_week, Time.now.end_of_week)
    assert_equal 5, bookings.size, "There should 5 bookings for the 5 days when Megan doesn't work"
    first_booking = bookings.first
    json = first_booking.to_json
    assert_valid_json(json)
    assert_match %r{"id":}, json
  end
  
  def test_bookings_for_non_working_days_with_sunday
    workaholic = Factory(:practitioner, :working_days => "1,2,3,4,5,6,7")
    bookings = workaholic.bookings_for_non_working_days(Time.now.beginning_of_week, Time.now.end_of_week)
    assert_equal 0, bookings.size, "There should 0 bookings as Workaholic works every day..."
  end
  
  def test_bookings_for_working_hours_simple
    simple = Factory(:practitioner, :working_days => "4,5", :lunch_break => false, :start_time1 => 9, :end_time1 => 18 )
    bookings = simple.bookings_for_working_hours(Time.now.beginning_of_week, Time.now.end_of_week)
    assert_equal 0, bookings.size, "There should 0 bookings as Simple works straight through. Actual: #{bookings.inspect}"
  end
    
  def test_bookings_for_working_hours_with_break
    simple = Factory(:practitioner, :working_days => "4,5", :lunch_break => true, :start_time1 => 9, :end_time1 => 12, :start_time2 => 13, :end_time2 => 18 )
    bookings = simple.bookings_for_working_hours(Time.now.beginning_of_week, Time.now.end_of_week)
    assert_equal 2, bookings.size, "There should 2 bookings for the breaks. Actual: #{bookings.inspect}"
  end
    
  def test_bookings_for_working_hours_with_break_full_week
    simple = Factory(:practitioner, :working_days => "1,2,3,4,5,6,7", :lunch_break => true, :start_time1 => 9, :end_time1 => 12, :start_time2 => 13, :end_time2 => 18 )
    bookings = simple.bookings_for_working_hours(Time.now.beginning_of_week, Time.now.end_of_week)
    assert_equal 7, bookings.size, "There should 7 bookings for the breaks. Actual: #{bookings.inspect}"
  end
    
  def test_valid
    assert Factory(:practitioner).valid?
  end
  
  def test_require_password
    assert new_practitioner(:password => '').errors.on(:password)
  end
  
  def test_require_phone_prefix
    assert new_practitioner(:phone_prefix => '').errors.on(:phone_prefix)
  end
  
  def test_require_phone_suffix
    assert new_practitioner(:phone_suffix => '').errors.on(:phone_suffix)
  end
  
  def test_require_well_formed_email
    assert new_practitioner(:email => 'foo@bar@example.com').errors.on(:email)
  end

  def test_times
    assert new_practitioner(:start_time1  => Time.now, :end_time1 => Time.now.advance(:hours => -1)).errors.on(:start_time1), "There should be an error on start_time1 as it is later than end_time1"
    assert new_practitioner(:lunch_break => true, :start_time2  => Time.now, :end_time2 => Time.now.advance(:hours => -1)).errors.on(:start_time2), "There should be an error on start_time2 as it is later than end_time2"    
  end
  
  def test_validate_uniqueness_of_email
    Factory(:practitioner, :email => 'bar@example.com')
    assert new_practitioner(:email => 'bar@example.com').errors.on(:email)
  end
    
  def test_validate_odd_characters_in_username
    assert new_practitioner(:username => 'odd ^&(@)').errors.on(:username)
  end
  
  def test_validate_password_length
    assert new_practitioner(:password => 'bad').errors.on(:password)
  end
  
  def test_require_matching_password_confirmation
    begin
      Factory(:practitioner, :password_confirmation => 'nonmatching').errors.on(:password)
    rescue ActiveRecord::RecordInvalid
      #expected exception
    else
      raise "An ActiveRecord::RecordInvalid should have been raised"
    end
  end
  
  def test_generate_password_hash_and_salt_on_create
    practitioner = Factory(:practitioner)
    assert practitioner.password_hash
    assert practitioner.password_salt
  end
  
  def test_authenticate_by_username
    Practitioner.delete_all
    practitioner = Factory(:practitioner, :username => 'foobar', :password => 'secret')
    practitioner.save!
    assert_equal practitioner, Practitioner.authenticate('foobar', 'secret')
  end
  
  def test_authenticate_by_email
    Practitioner.delete_all
    practitioner = Factory(:practitioner, :email => 'foo@bar.com', :password => 'secret')
    practitioner.save!
    assert_equal practitioner, Practitioner.authenticate('foo@bar.com', 'secret')
  end
  
  def test_authenticate_bad_username
    assert_nil Practitioner.authenticate('nonexisting', 'secret')
  end
  
  def test_authenticate_bad_password
    Practitioner.delete_all
    Factory(:practitioner, :username => 'foobar', :password => 'secret')
    assert_nil Practitioner.authenticate('foobar', 'badpassword')
  end
end
