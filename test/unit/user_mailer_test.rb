require File.dirname(__FILE__) + '/../test_helper'

class UserMailerTest < ActionMailer::TestCase

  # def test_pro_invite
  #   pro = Factory(:practitioner, :country => countries(:fr))
  #   client = Factory(:client, :practitioner => pro)
  #   booking = Factory(:booking, :client => client, :practitioner => pro)
  #   
  #   new_email = UserMailer.create_pro_invite(pro.email, "myapp@test.com", "Rendez-vous", booking)
  #   assert_match /rendez-vous/, new_email.body, "The email body should be in French (it should contain the word: rendez-vous)"
  #   
  # end

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
