require File.dirname(__FILE__) + '/../test_helper'

class BookingsControllerTest < ActionController::TestCase
  def test_index
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.beginning_of_week, :end => Time.now.end_of_week}
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 2, assigns(:bookings).size, "Sav should have 1 booking and 1 non-working day, but bookings are: #{assigns(:bookings).to_json}"
  end

  def test_index_megan
    get :index, {:practitioner_id => practitioners(:megan).permalink, :format => "json", :start => Time.now.beginning_of_week, :end => Time.now.end_of_week}, {:client_id => clients(:cyrille).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 5, assigns(:bookings).size, "Megan should have 2 bookings and 3 non-working days, but bookings are: #{assigns(:bookings).to_json}"
    assert_match %r{Cyrille Bonnet}, @response.body, "Since Cyrille is logged in, his name should be revealed"
    assert_no_match %r{Kartini}, @response.body, "Since Cyrille is logged in, K's name should NOT be revealed"
  end

  def test_index_next_week
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.end_of_week, :end => Time.now.end_of_week.advance(:days => 7 )}
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 1, assigns(:bookings).size, "Sav should have 0 booking and 1 non-working day, but bookings are: #{assigns(:bookings).to_json}"
  end
end
