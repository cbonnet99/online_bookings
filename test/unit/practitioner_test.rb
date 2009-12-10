require File.dirname(__FILE__) + '/../test_helper'

class PractitionerTest < ActiveSupport::TestCase
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
  
  def test_all_bookings
    megan = Factory(:practitioner, :working_days => "4,5")
    cyrille = Factory(:client)
    k = Factory(:client)
    booking = Factory(:booking, :client => cyrille, :practitioner => megan )
    booking = Factory(:booking, :client => k, :practitioner => megan )
    megan_bookings = megan.all_bookings(cyrille, Time.now.beginning_of_week.to_f, Time.now.end_of_week.to_f)
    assert megan_bookings.is_a?(Enumerable)
    assert_equal 5, megan_bookings.size
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
    assert_equal 3, bookings.size, "There should 3 bookings for the 3 days when Megan doesn't work"
    first_booking = bookings.first
    json = first_booking.to_json
    assert_valid_json(json)
    assert_match %r{"id":}, json
  end
  
  def test_valid
    assert new_practitioner.valid?
  end
  
  def test_require_password
    assert new_practitioner(:password => '').errors.on(:password)
  end
  
  def test_require_well_formed_email
    assert new_practitioner(:email => 'foo@bar@example.com').errors.on(:email)
  end
  
  def test_validate_uniqueness_of_email
    new_practitioner(:email => 'bar@example.com').save!
    assert new_practitioner(:email => 'bar@example.com').errors.on(:email)
  end
    
  def test_validate_odd_characters_in_username
    assert new_practitioner(:username => 'odd ^&(@)').errors.on(:username)
  end
  
  def test_validate_password_length
    assert new_practitioner(:password => 'bad').errors.on(:password)
  end
  
  def test_require_matching_password_confirmation
    assert new_practitioner(:password_confirmation => 'nonmatching').errors.on(:password)
  end
  
  def test_generate_password_hash_and_salt_on_create
    practitioner = new_practitioner
    practitioner.save!
    assert practitioner.password_hash
    assert practitioner.password_salt
  end
  
  def test_authenticate_by_username
    Practitioner.delete_all
    practitioner = new_practitioner(:username => 'foobar', :password => 'secret')
    practitioner.save!
    assert_equal practitioner, Practitioner.authenticate('foobar', 'secret')
  end
  
  def test_authenticate_by_email
    Practitioner.delete_all
    practitioner = new_practitioner(:email => 'foo@bar.com', :password => 'secret')
    practitioner.save!
    assert_equal practitioner, Practitioner.authenticate('foo@bar.com', 'secret')
  end
  
  def test_authenticate_bad_username
    assert_nil Practitioner.authenticate('nonexisting', 'secret')
  end
  
  def test_authenticate_bad_password
    Practitioner.delete_all
    new_practitioner(:username => 'foobar', :password => 'secret').save!
    assert_nil Practitioner.authenticate('foobar', 'badpassword')
  end
end
