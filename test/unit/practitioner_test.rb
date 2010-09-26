require File.dirname(__FILE__) + '/../test_helper'

class PractitionerTest < ActiveSupport::TestCase
  
  include ColibriExceptions
  
  fixtures :all

  def test_delete_sample_data
    pro = Factory(:practitioner, :state => "test_user")
    pro.create_sample_data!
    pro.delete_sample_data!
  end
  
  def test_delete_sample_data_for_non_test_user
    pro = Factory(:practitioner, :state => "active")
    client = Factory(:client)
    booking = Factory(:booking, :practitioner => pro, :client => client)
    assert_raise(CantDeleteSampleDataOnNonTestProException) do
      pro.delete_sample_data!
    end
    pro.reload
    assert_equal 1, pro.clients.size
    assert_equal 1, pro.bookings.size
  end
  

  def test_create_sample_data_for_non_test_user
    pro = Factory(:practitioner, :state => "active")
    assert_raise(CantCreateSampleDataOnNonTestProException){
      pro.create_sample_data!
    }
    
  end

  def test_create_sample_data
    pro = Factory(:practitioner, :state => "test_user")
    pro.create_sample_data!
    pro.reload
    assert_equal 30, pro.clients.size
    assert_equal 300, pro.bookings.size
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
    booking = Factory(:booking, :practitioner => pro, :prep_before => false, :prep_time_mins => 30, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now)
    #just in case we run these tests on a Sunday after 10PM, I'll take the end of next week...
    my_own_bookings = pro.own_bookings(Time.now.beginning_of_week, Time.now.next_week.end_of_week)
    assert my_own_bookings.include?(booking)
    assert !my_own_bookings.select{|b| b.title == "Prep time"}.blank?
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
    booking = Factory(:booking, :practitioner => pro, :client => client, :prep_before => false, :prep_time_mins => 30, :starts_at => 2.hours.from_now, :ends_at => 3.hours.from_now)
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

  def test_client_with_empty_cancel_period
    assert_raise ActiveRecord::RecordInvalid do
      Factory(:practitioner, :no_cancellation_period_in_hours  => nil)
    end
    Factory(:practitioner, :no_cancellation_period_in_hours  => 0)
  end

  def test_add_client_existing
    pro = Factory(:practitioner)
    client = Factory(:client)
    old_overall_size = Client.all.size
    old_size = pro.clients.size
        
    pro.add_clients(client.email, false, "", "")
    assert_equal old_overall_size, Client.all.size
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
    assert_equal old_size, Client.all.size
    assert_equal old_name, client.name, "Client name shouldn't have changed"
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    new_email = ActionMailer::Base.deliveries.first
    assert_equal [client.email], new_email.to
    assert_equal [pro.email], new_email.from
    assert_match %r{Dear #{client.first_name},}, new_email.body    
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
      assert_equal 2, e.message.gsub(/and/, ",").split(",").size, "There should 2 invalid emails, but message was: #{e.message}"       
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
    remind_me = Factory(:booking, :starts_at => 1.day.from_now, :practitioner_id => pro.id)
    dont_remind_me_already_passed = Factory(:booking, :starts_at => 1.day.ago, :practitioner_id => pro.id)
    dont_remind_me_too_far_in_the_future = Factory(:booking, :starts_at => 2.days.from_now, :practitioner_id => pro.id)
    dont_remind_me_already_sent = Factory(:booking, :starts_at => 1.day.from_now, :pro_reminder_sent_at => Time.now, :practitioner_id => pro.id)
    
    assert_equal 1, pro.bookings.need_pro_reminder.size, "Bookings are: #{pro.bookings.need_pro_reminder.inspect}"
  end
  
  def test_clients_options
    megan = Factory(:practitioner, :working_days => "4,5")
    cyrille = Factory(:client)
    k = Factory(:client)
    booking = Factory(:booking, :client => cyrille, :practitioner => megan )
    booking = Factory(:booking, :client => k, :practitioner => megan )
    opts = megan.clients_options
    assert_equal 2, opts.size
    assert_equal [cyrille.name, cyrille.id], opts.first
  end

  def test_all_bookings
    megan = Factory(:practitioner, :working_days => "4,5")
    cyrille = Factory(:client, :first_name => "Cyrille", :last_name => "Bonnet")
    k = Factory(:client, :first_name => "Ms", :last_name => "K")
    booking1 = Factory(:booking, :client => cyrille, :practitioner => megan)
    booking2 = Factory(:booking, :client => k, :practitioner => megan )
    booking_cancelled = Factory(:booking, :state => "cancelled",  :client => k, :practitioner => megan )
    megan_bookings = megan.all_bookings(cyrille, Time.now.beginning_of_week.to_f, Time.now.end_of_week.to_f)
    assert megan_bookings.is_a?(Enumerable)
    assert_equal 7, megan_bookings.size, "Megan bookings seen by Cyrille are: #{megan_bookings.inspect}"
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
    simple = Factory(:practitioner, :working_days => "4,5", :working_hours => "9-18" )
    bookings = simple.bookings_for_working_hours(Time.now.beginning_of_week, Time.now.end_of_week)
    assert_equal 0, bookings.size, "There should 0 bookings as Simple works straight through. Actual: #{bookings.inspect}"
  end
  
  def test_bookings_for_working_hours_with_slots
    user_with_slots = Factory(:practitioner, :working_days => "4,5", :working_hours => "9-10,10:30-11:30,12-13,13:30-14:30,15-16,16:30-17:30")
    bookings = user_with_slots.bookings_for_working_hours(Time.now.beginning_of_week, Time.now.end_of_week)
    assert_equal 12, bookings.size, "There should 12 bookings as user_with_slots works in slots: 6 slots in 2 working days (including one at the end: from 17:30 to 18). Actual: #{bookings.inspect}"
    assert_not_nil bookings.last
    assert_equal "18", bookings.last.end_time.strftime("%H")
  end
  
  def test_bookings_for_working_hours_with_slots_extended_period
    user_with_slots = Factory(:practitioner, :working_days => "4,5", :working_hours => "9-10,10:30-11:30,12-13,13:30-14:30,15-16,16:30-17:30")
    bookings = user_with_slots.bookings_for_working_hours(Time.now.beginning_of_week.advance(:days => -7), Time.now.end_of_week.advance(:days => 7))
    assert_equal 36, bookings.size, "There should 36 bookings as user_with_slots works in slots: 3 times as many as above, as we are asking for 3 weeks. Actual: #{bookings.inspect}"
  end
  
  def test_valid
    assert Factory(:practitioner).valid?
  end
  
  def test_require_password
    assert new_practitioner(:password => '').errors.on(:password)
  end
  
  def test_require_well_formed_email
    assert new_practitioner(:email => 'foo@bar@example.com').errors.on(:email)
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
