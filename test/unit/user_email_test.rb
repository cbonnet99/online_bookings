require File.dirname(__FILE__) + '/../test_helper'

class UserEmailTest < ActiveSupport::TestCase
  def test_send_unsent_emails
    ActionMailer::Base.deliveries.clear
    Factory(:user_email, :email_type => UserEmail::PRO_INVITE)
    Factory(:user_email, :email_type => UserEmail::CLIENT_INVITE)
    Factory(:user_email, :email_type => UserEmail::PRO_INVITE, :delay_mins => 1 )
    Factory(:user_email, :email_type => UserEmail::CLIENT_INVITE, :sent_at => 1.day.ago)
    
    UserEmail.send_unsent_emails
    assert_equal 2, ActionMailer::Base.deliveries.size, "Only 2 emails should have been sent"
  end
end
