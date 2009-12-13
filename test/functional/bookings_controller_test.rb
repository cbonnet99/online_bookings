require File.dirname(__FILE__) + '/../test_helper'

class BookingsControllerTest < ActionController::TestCase

  def test_create_empty
    post :create, :format => "json" 
    assert_response :success
    assert_equal "Not authenticated as a client", flash[:error]
  end


  def test_create
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = Booking.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "Joe Sullivan", :comment => "I'll be on time", :booking_type => 0.5, 
      :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
      :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
      {:client_id => cyrille.id }
    # puts @response.body 
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = Booking.all.last
    assert_equal "Joe Sullivan", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
  end

  def test_index
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.beginning_of_week, :end => Time.now.end_of_week}
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 3, assigns(:bookings).size, "Sav should have 0 booking and 3 non-working days, but bookings are: #{assigns(:bookings).to_json}"
  end

  def test_index_megan_next_week
    get :index, {:practitioner_id => practitioners(:megan).permalink, :format => "json", :start => Time.now.end_of_week, :end => Time.now.end_of_week.advance(:days => 7 )}, {:client_id => clients(:cyrille).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 7, assigns(:bookings).size, "Megan should have 2 bookings and 5 non-working days, but bookings are: #{assigns(:bookings).to_json}"
    assert_match %r{Cyrille Bonnet}, @response.body, "Since Cyrille is logged in, his name should be revealed"
    assert_no_match %r{Kartini}, @response.body, "Since Cyrille is logged in, K's name should NOT be revealed"
  end

  def test_index_next_week
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.end_of_week, :end => Time.now.end_of_week.advance(:days => 7 )}
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 4, assigns(:bookings).size, "Sav should have 1 booking and 3 non-working day, but bookings are: #{assigns(:bookings).to_json}"
  end  
end
