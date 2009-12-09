require File.dirname(__FILE__) + '/../test_helper'

class BookingsControllerTest < ActionController::TestCase
  def test_index
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => 5.days.ago.to_f, :end => 2.days.from_now.to_f}
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 1, assigns(:bookings).size
  end
  def test_index_next_week
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => 2.days.from_now.to_f, :end => 9.days.from_now.to_f}
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 0, assigns(:bookings).size
  end
end
