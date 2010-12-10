require File.dirname(__FILE__) + '/../test_helper'

class UserEmailTest < ActiveSupport::TestCase
  
  def test_send_unsent_emails
    ActionMailer::Base.deliveries.clear
    ue1 = Factory(:user_email, :email_type => UserEmail::PRO_INVITE)
    ue2 = Factory(:user_email, :email_type => UserEmail::CLIENT_INVITE)
    assert_nil ue1.sent_at
    assert_nil ue2.sent_at
    ue3 = Factory(:user_email, :email_type => UserEmail::PRO_INVITE, :delay_mins => 1 )
    ue4 = Factory(:user_email, :email_type => UserEmail::CLIENT_INVITE, :sent_at => 1.day.ago)
    assert_nil ue3.sent_at
    assert_not_nil ue4.sent_at
    
    #SUT
    UserEmail.send_unsent_emails
    
    #Assertions
    assert_equal 2, ActionMailer::Base.deliveries.size, "Only 2 emails should have been sent (the delayed email and the already sent should NOT have been sent)"
    ue1.reload
    ue2.reload
    ue3.reload
    ue4.reload
    assert_not_nil ue1.sent_at
    assert_not_nil ue2.sent_at
    assert_nil ue3.sent_at
    assert_not_nil ue4.sent_at
  end
  
  def test_send_unsent_emails_for_test_user
    ActionMailer::Base.deliveries.clear
    test_pro = Factory(:practitioner, :state => "test_user")
    email_to_self = Factory(:user_email, :practitioner => test_pro, :from => test_pro.email,  :to => test_pro.email, :email_type => UserEmail::PRO_INVITE)
    email_to_other = Factory(:user_email, :practitioner => test_pro, :from => test_pro.email,  :to => "bla@test.com", :email_type => UserEmail::PRO_INVITE)
    
    #SUT
    UserEmail.send_unsent_emails
    
    #Assertions
    assert_equal 1, ActionMailer::Base.deliveries.size, "Only the email to self should have been sent"
    email = ActionMailer::Base.deliveries[0]
    assert_equal [test_pro.email], email.to
    
  end
end
