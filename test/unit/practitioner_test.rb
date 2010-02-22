require File.dirname(__FILE__) + '/../test_helper'

class PractitionerTest < ActiveSupport::TestCase
  fixtures :all
  
  def new_practitioner(attributes = {})
    attributes[:username] ||= 'foo'
    attributes[:email] ||= 'foo@example.com'
    attributes[:password] ||= 'abc123'
    attributes[:password_confirmation] ||= attributes[:password]
    practitioner = Practitioner.new(attributes)
    practitioner.valid? # run validations
    practitioner
  end
  
  def setup
    Practitioner.delete_all
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
    cyrille = Factory(:client)
    k = Factory(:client)
    booking1 = Factory(:booking, :client => cyrille, :practitioner => megan )
    booking2 = Factory(:booking, :client => k, :practitioner => megan )
    booking_cancelled = Factory(:booking, :state => "cancelled",  :client => k, :practitioner => megan )
    megan_bookings = megan.all_bookings(cyrille, Time.now.beginning_of_week.to_f, Time.now.end_of_week.to_f)
    assert megan_bookings.is_a?(Enumerable)
    assert_equal 7, megan_bookings.size
    cyrille_booking = megan_bookings.select{|b| b.is_a?(Booking) && b.client_id == cyrille.id}.first
    assert !cyrille_booking.read_only?
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
