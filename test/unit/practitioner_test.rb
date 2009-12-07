require 'test_helper'

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
  
  def test_valid
    assert new_practitioner.valid?
  end
  
  def test_require_username
    assert new_practitioner(:username => '').errors.on(:username)
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
  
  def test_validate_uniqueness_of_username
    new_practitioner(:username => 'uniquename').save!
    assert new_practitioner(:username => 'uniquename').errors.on(:username)
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
