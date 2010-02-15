require File.dirname(__FILE__) + '/../test_helper'

class TaskUtilsTest < ActiveSupport::TestCase
  
  def test_send_reminders
    ActionMailer::Base.deliveries.clear
    remind_me = Factory(:booking, :starts_at => 1.day.from_now.advance(:minutes => -30))
    dont_remind_me = Factory(:booking, :state => "reminder_sent",  :starts_at => 1.day.from_now.advance(:minutes => -30))
    
    TaskUtils.send_reminders
    
    assert_equal 1, ActionMailer::Base.deliveries.size

    ActionMailer::Base.deliveries.clear
    TaskUtils.send_reminders
    assert_equal 0, ActionMailer::Base.deliveries.size
    
  end
  
end