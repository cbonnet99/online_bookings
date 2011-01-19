require File.dirname(__FILE__) + '/../test_helper'

class ClientTest < ActiveSupport::TestCase
  def new_client(attributes = {})
    attributes[:username] ||= 'foo'
    attributes[:email] ||= 'foo@example.com'
    attributes[:password] ||= 'abc123'
    attributes[:password_confirmation] ||= attributes[:password]
    client = Client.new(attributes)
    client.valid? # run validations
    client
  end
  
  def setup
    Client.delete_all
  end
  
  def test_to_json
    client = Factory(:client)
    json = client.to_json
    assert_valid_json(json)
    assert_match %r{"label"}, json
    assert_match %r{"value"}, json
  end
  
  def test_empty_email
    c = Client.new(:name=>"toto", :phone_prefix=>"06", :phone_suffix=>"231231231")
    assert c.valid?
  end
  
  def test_validate_phone
    c = Factory(:client, :phone_prefix => "06", :phone_suffix => "14 54 34 23")
    assert c.valid?
    
    assert_raise ActiveRecord::RecordInvalid do
      c = Factory(:client, :phone_prefix => "06", :phone_suffix => "14 54")
    end
  end
  
  def test_validate_email
    assert Client.valid_email?("cyrille@test.com")
    assert !Client.valid_email?("cyrille@test/com")
    assert !Client.valid_email?("cyrille@test")
    assert !Client.valid_email?("@test.com")
    assert !Client.valid_email?("cyrilletest.com")
  end
  
  def test_default_name
    c = Factory(:client, :first_name => "", :last_name => "" )
    assert_equal c.email, c.default_name
  end
  
  def test_cleanup_phone
    c = Factory(:client, :phone_prefix => "0 2-1/", :phone_suffix => "88 876-23/13"  )
    assert_equal "021", c.phone_prefix
    assert_equal "888762313", c.phone_suffix
  end
  
  def test_phone_without_last4digits
    c = Factory(:client, :phone_prefix => "021", :phone_suffix => "888762313"  )
    assert_equal "021-88876", c.phone_without_last4digits
  end
  
  def test_phone_without_last4digits_longer
    c = Factory(:client, :phone_prefix => "021", :phone_suffix => "8887623135"  )
    assert_equal "021-888762", c.phone_without_last4digits
  end
  
  def test_valid
    assert new_client.valid?
  end
    
  def test_require_well_formed_email
    assert new_client(:email => 'foo@bar@example.com').errors.on(:email)
  end
  
  def test_validate_uniqueness_of_email
    new_client(:email => 'bar@example.com').save!
    assert new_client(:email => 'bar@example.com').errors.on(:email)
  end
  
  def test_validate_password_length
    assert new_client(:password => 'bad').errors.on(:password)
  end
  
  def test_require_matching_password_confirmation
    assert new_client(:password_confirmation => 'nonmatching').errors.on(:password)
  end
  
  def test_generate_password_hash_and_salt_on_create
    client = new_client
    client.save!
    assert client.password_hash
    assert client.password_salt
  end
  
  def test_authenticate_by_email
    Client.delete_all
    client = new_client(:email => 'foo@bar.com', :password => 'secret')
    client.save!
    assert_equal client, Client.authenticate('foo@bar.com', 'secret')
  end
  
  def test_authenticate_bad_username
    assert_nil Client.authenticate('nonexisting', 'secret')
  end
  
  def test_authenticate_bad_password
    Client.delete_all
    new_client(:username => 'foobar', :password => 'secret').save!
    assert_nil Client.authenticate('foobar', 'badpassword')
  end
end
