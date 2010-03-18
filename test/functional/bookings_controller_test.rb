require File.dirname(__FILE__) + '/../test_helper'

class BookingsControllerTest < ActionController::TestCase

  def test_confirm
    booking = Factory(:booking)
    assert booking.unconfirmed?
    assert_not_nil booking.confirmation_code
    post :confirm, {:id => booking.id, :confirmation_code => booking.confirmation_code}
    assert_response :success
    assert_not_nil flash[:notice]
    assert_match %r{#{booking.practitioner.name}}, flash[:notice]
    booking.reload
    assert booking.confirmed?
  end

  def test_cancel
    booking = Factory(:booking)
    assert booking.unconfirmed?
    assert_not_nil booking.confirmation_code
    post :cancel, {:id => booking.id, :confirmation_code => booking.confirmation_code}
    assert_response :success
    booking.reload
    assert booking.cancelled?
  end

  def test_destroy_client
    cyrille_sav = bookings(:cyrille_sav)
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = Booking.all.size
    post :destroy, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id},
     {:client_id => cyrille.id }
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size-1, Booking.all.size
  end

  def test_destroy_pro
    cyrille_sav = bookings(:cyrille_sav)
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = Booking.all.size
    post :destroy, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id},
     {:pro_id => sav.id }
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size-1, Booking.all.size
  end

  def test_create_empty
    post :create, :format => "json" 
    assert_redirected_to flash_url
    assert_equal "No selected practitioner", flash[:error]
  end

  def test_update_no_client
    cyrille_sav = bookings(:cyrille_sav)
    sav = practitioners(:sav)
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:name => "John Denver"} }
    assert_redirected_to flash_url
    assert_not_nil flash[:error]
  end
  
  def test_update_as_client
    cyrille_sav = bookings(:cyrille_sav)
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    kartini = clients(:kartini)
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:name => "John Denver", :client_id  => kartini.id} }, {:client_id => cyrille.id }
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    cyrille_sav.reload
    assert_equal cyrille.id, cyrille_sav.client_id, "Even though the client tried to cheat and send Kartini's as client_id, it should stay with the currently logged in client (Cyrille)"
    assert_equal "John Denver", cyrille_sav.name
    cyrille.reload
    assert_equal "John Denver", cyrille.name
  end

  def test_update_as_pro
    cyrille_sav = bookings(:cyrille_sav)
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    kartini = clients(:kartini)
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:client_id => kartini.id } }, {:pro_id => sav.id }
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    cyrille_sav.reload
    assert_equal kartini.default_name, cyrille_sav.name
    assert_equal kartini.id, cyrille_sav.client_id
  end

  def test_create
    mail_size = UserEmail.all.size
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
    assert_match %r{#{assigns["booking"].practitioner.name}}, flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = Booking.all.last
    assert_equal "Joe Sullivan", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
    assert_equal sav.id, new_booking.practitioner_id
    cyrille.reload
    assert_equal "Joe", cyrille.first_name
    assert_equal "Sullivan", cyrille.last_name
    assert_equal mail_size+1, UserEmail.all.size
    new_email = UserEmail.last
    assert_equal sav.email, new_email.to
    assert_match /#{cyrille.name}/, new_email.subject
  end

  def test_create_pro
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "undefined", :client_id => cyrille.id, :comment => "I'll be on time", :booking_type => 0.5, 
      :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
      :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
      {:pro_id => sav.id }
    # puts @response.body
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = Booking.all.last
    assert_equal "Cyrille Bonnet", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
    assert_equal mail_size+1, UserEmail.all.size
    new_email = UserEmail.last
    assert_equal cyrille.email, new_email.to
    assert_match /#{sav.name}/, new_email.subject
  end

  def test_index_cal
    sav = practitioners(:sav)
    get :index_cal, {:pub_code => sav.bookings_publish_code, :practitioner_id => sav.permalink, :format => "ics"}
    assert_response :success
    assert_not_nil assigns(:practitioner)
    assert_not_nil assigns(:bookings)
    assert !assigns(:bookings).blank?
  end

  def test_index
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.beginning_of_week, :end => Time.now.end_of_week}, {:client_id => clients(:cyrille).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 17, assigns(:bookings).size, "Sav should have 0 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working days, but bookings are: #{assigns(:bookings).to_json}"
  end

  def test_index_sav_self
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.beginning_of_week, :end => Time.now.end_of_week}, {:pro_id => practitioners(:sav).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 17, assigns(:bookings).size, "Sav should have 0 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working days, but bookings are: #{assigns(:bookings).to_json}"
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
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.end_of_week, :end => Time.now.end_of_week.advance(:days => 7 )}, {:client_id => clients(:cyrille).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 18, assigns(:bookings).size, "Sav should have 1 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working day, but bookings are: #{assigns(:bookings).to_json}"
  end  

  def test_index_sav_own_next_week
    get :index, {:practitioner_id => practitioners(:sav).permalink, :format => "json", :start => Time.now.end_of_week, :end => Time.now.end_of_week.advance(:days => 7 )}, {:pro_id => practitioners(:sav).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 18, assigns(:bookings).size, "Sav should have 1 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working day, but bookings are: #{assigns(:bookings).to_json}"
    first_booking = assigns(:bookings).first
    assert !first_booking.read_only?, "The first booking (a booking by a client) should be editable, but it is read only"
    assert_not_equal "Booked", first_booking.name, "The client name for the first booking (a booking by a client) should be visible to the practitioner"
  end  
end
