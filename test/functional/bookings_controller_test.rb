require File.dirname(__FILE__) + '/../test_helper'

class BookingsControllerTest < ActionController::TestCase
  def test_index
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json" }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 1, assigns(:bookings).size
  end
end
