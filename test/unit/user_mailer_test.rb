require File.dirname(__FILE__) + '/../test_helper'

class UserMailerTest < ActionMailer::TestCase
  def test_initial_client_email
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner)
    client = Factory(:client, :first_name => "", :last_name => "")
    
    new_email = UserMailer.create_initial_client_email(pro, client, "This is a test", "Cheers")
    assert_equal [client.email], new_email.to
    assert_equal [pro.email], new_email.from
    assert_match /Hello,/, new_email.body
    
  end
  
  def test_initial_client_email_with
    ActionMailer::Base.deliveries.clear
    pro = Factory(:practitioner)
    client = Factory(:client, :first_name => "Joe")
    
    new_email = UserMailer.create_initial_client_email(pro, client, "This is a test", "Cheers")
    assert_equal [client.email], new_email.to
    assert_equal [pro.email], new_email.from
    assert_match /Dear Joe,/, new_email.body
    
  end
end
