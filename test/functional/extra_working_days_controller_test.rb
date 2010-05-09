require File.dirname(__FILE__) + '/../test_helper'

class ExtraWorkingDaysControllerTest < ActionController::TestCase
  def test_create
    pro = Factory(:practitioner)
    old_count = pro.extra_working_days.size
    non_working_days = pro.bookings_for_non_working_days(Time.now, 1.week.from_now)
    post :create, {:day_date  => non_working_days.first}, {:pro_id => pro.id}
    assert_response :success
    assert_not_nil flash[:notice]
    assert_nil flash[:error]
    pro.reload
    assert_equal old_count+1, pro.extra_working_days.size
  end
end
