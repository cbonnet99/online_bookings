require File.dirname(__FILE__) + '/../test_helper'

class WorkingDaysControllerTest < ActionController::TestCase
  def test_create
    pro = Factory(:practitioner)
    old_count = pro.extra_working_days.size
    non_working_days = pro.non_working_days_in_timeframe(Time.now, 1.week.from_now)
    post :create, {:day_date  => non_working_days.first}, {:pro_id => pro.id}
    assert_response :success
    assert_nil flash[:error], "Flash was: #{flash.inspect}"
    assert_not_nil flash[:notice], "Flash was: #{flash.inspect}"
    pro.reload
    assert_equal old_count+1, pro.extra_working_days.size
  end
  
  def test_create_existing_extra_non_working_day
    pro = Factory(:practitioner)
    working_days = pro.working_days_in_timeframe(Time.now, 1.week.from_now)
    non_working_day = Factory(:extra_non_working_day, :day_date => working_days.first, :practitioner => pro)
    old_count = pro.extra_working_days.size
    old_count_non = pro.extra_non_working_days.size
    post :create, {:day_date  => non_working_day.day_date}, {:pro_id => pro.id}
    assert_response :success
    assert_nil flash[:error], "Flash was: #{flash.inspect}"
    assert_not_nil flash[:notice], "Flash was: #{flash.inspect}"
    pro.reload
    assert_equal old_count, pro.extra_working_days.size
    assert_equal old_count_non-1, pro.extra_non_working_days.size
  end
  
  def test_create_error
    pro = Factory(:practitioner)
    old_count = pro.extra_working_days.size
    working_days = pro.working_days_in_timeframe(Time.now, 1.week.from_now)
    post :create, {:day_date  => working_days.first}, {:pro_id => pro.id}
    assert_response :success
    assert_not_nil flash[:error], "Flash was: #{flash.inspect}"
    assert_nil flash[:notice], "Flash was: #{flash.inspect}"
    pro.reload
    assert_equal old_count, pro.extra_working_days.size
  end
  
  def test_destroy_existing_extra_working_day
    pro = Factory(:practitioner)
    non_working_days = pro.non_working_days_in_timeframe(Time.now, 1.week.from_now)
    working_day = Factory(:extra_working_day, :day_date => non_working_days.first, :practitioner => pro)
    old_count = pro.extra_working_days.size
    post :destroy, {:day_date => working_day.day_date }, {:pro_id => pro.id}
    assert_response :success
    assert_nil flash[:error], "Flash was: #{flash.inspect}"
    assert_not_nil flash[:notice], "Flash was: #{flash.inspect}"
    pro.reload
    assert_equal old_count-1, pro.extra_working_days.size
  end
  
  def test_destroy_error_existing_bookings
    pro = Factory(:practitioner)
    Time.zone = pro.timezone
    non_working_days = pro.non_working_days_in_timeframe(Time.zone.now, 1.week.from_now)
    working_day = Factory(:extra_working_day, :day_date => non_working_days.first, :practitioner => pro)
    booking = Factory(:booking, :practitioner => pro,
                      :starts_str => starts_str_builder(working_day.day_date),
                      :ends_str => ends_str_builder(working_day.day_date)
    )
    old_count = pro.extra_working_days.size
    post :destroy, {:day_date => working_day.day_date }, {:pro_id => pro.id}
    assert_response :success
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
    pro.reload
    assert_equal old_count, pro.extra_working_days.size
  end
  
end
