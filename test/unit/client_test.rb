require 'test_helper'

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
  
  def test_valid
    assert new_client.valid?
  end
  
  def test_require_username
    assert new_client(:username => '').errors.on(:username)
  end
  
  def test_require_password
    assert new_client(:password => '').errors.on(:password)
  end
  
  def test_require_well_formed_email
    assert new_client(:email => 'foo@bar@example.com').errors.on(:email)
  end
  
  def test_validate_uniqueness_of_email
    new_client(:email => 'bar@example.com').save!
    assert new_client(:email => 'bar@example.com').errors.on(:email)
  end
  
  def test_validate_uniqueness_of_username
    new_client(:username => 'uniquename').save!
    assert new_client(:username => 'uniquename').errors.on(:username)
  end
  
  def test_validate_odd_characters_in_username
    assert new_client(:username => 'odd ^&(@)').errors.on(:username)
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
  
  def test_authenticate_by_username
    Client.delete_all
    client = new_client(:username => 'foobar', :password => 'secret')
    client.save!
    assert_equal client, Client.authenticate('foobar', 'secret')
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
