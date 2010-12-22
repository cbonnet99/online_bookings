require File.dirname(__FILE__) + '/../test_helper'

class PractitionersControllerTest < ActionController::TestCase

  def test_new
    get :new
    assert_template 'new'
    assert_not_nil assigns(:practitioner)
    france = Country.find_by_country_code("FR")
    assert_equal france.id, assigns(:practitioner).country_id
  end

  def test_reset_ical_sharing_on
    megan = Factory(:practitioner, :bookings_publish_code => "")
    post :reset_ical_sharing, {:id => megan.id }, {:pro_id => megan.id}
    assert_response :success
    megan.reload
    assert !megan.bookings_publish_code.blank?
  end

  def test_reset_ical_sharing_off
    megan = Factory(:practitioner, :bookings_publish_code => "1234")
    post :reset_ical_sharing, {:id => megan.id }, {:pro_id => megan.id}
    assert_response :success
    megan.reload
    assert megan.bookings_publish_code.blank?
  end

  def test_create
    old_size = Practitioner.all.size
    france = countries(:fr)
    post :create, :practitioner => {:sample_data => false, :email => "cb@test.com", :phone_prefix => "06", :phone_suffix => "221312312", :first_name => "Joe",
       :last_name => "Test", :password => "blabla", :password_confirmation => "blabla",
        :working_day_monday => "1", :lunch_break => true, :start_time1 => 9, :end_time1  => 12, :start_time2 => 13, :end_time2 => 18, :country_id  => france.id }
    assert_not_nil assigns(:practitioner)
    assert_equal 0, assigns(:practitioner).errors.size, "There are unexpected errors on new pro: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_redirected_to practitioner_url(assigns(:practitioner).permalink)
    assert_not_nil assigns(:practitioner)
    assert assigns(:practitioner).errors.blank?, "Errors found: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_equal "1", assigns(:practitioner).working_days
    assert_not_nil assigns(:practitioner).permalink
    assert assigns(:practitioner).lunch_break?
    assert_equal france.default_timezone, assigns(:practitioner).timezone
    assert_equal 0, assigns(:practitioner).bookings.size, "No sample data should be created"
    assert_nil flash[:error]
    assert_equal old_size+1, Practitioner.all.size
  end

  def test_create_with_sample_data
    old_size = Practitioner.all.size
    post :create, :practitioner => {:sample_data => true, :email => "cb@test.com", :phone_prefix => "06", :phone_suffix => "221312312", :first_name => "Joe",
       :last_name => "Test", :password => "blabla", :password_confirmation => "blabla",
        :working_day_monday => "1", :lunch_break => true, :start_time1 => 9, :end_time1  => 12, :start_time2 => 13, :end_time2 => 18, :country_id  => countries(:fr).id }
    assert_not_nil assigns(:practitioner)
    assert_equal 0, assigns(:practitioner).errors.size, "There are unexpected errors on new pro: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_redirected_to practitioner_url(assigns(:practitioner).permalink)
    assert_not_nil assigns(:practitioner)
    assert assigns(:practitioner).errors.blank?, "Errors found: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_equal "1", assigns(:practitioner).working_days
    assert_not_nil assigns(:practitioner).permalink
    assert assigns(:practitioner).lunch_break?
    assert assigns(:practitioner).bookings.size > 0, "Sample data should have been created"
    assert_nil flash[:error]
    assert_equal old_size+1, Practitioner.all.size
  end

  def test_create_error
    old_size = Practitioner.all.size
    post :create, :practitioner => {:lunch_break => false, :start_time1 => 9, :end_time1  => 16}
    assert_not_nil assigns(:practitioner)
    assert assigns(:practitioner).errors.size > 0, "There should be some errors"
    assert_not_nil assigns(:practitioner)
    assert !assigns(:practitioner).lunch_break?
    assert_equal 9, assigns(:practitioner).start_time1
    assert_equal 16, assigns(:practitioner).end_time1
    assert_equal old_size, Practitioner.all.size
  end

  def test_edit_selected
    get :edit_selected
    assert_template 'edit_selected'
  end
  
  def test_edit_selected_invalid_cookie
    cookies[:practitioner_id] = 999
    get :edit_selected
    assert_template 'edit_selected'
    assert_nil cookies[:practitioner_id], "Invalid cookies should be deleted"
  end
  
  def test_update_selected
    sav = practitioners(:sav)
    post :update_selected, :practitioner_id => sav.id
    assert_redirected_to sav
  end
  
  def test_clear_selected
    sav = practitioners(:sav)
    cookies[:practitioner_id] = sav.id
    post :clear_selected
    assert_redirected_to root_url
    assert_nil cookies[:practitioner_id]
  end
  
  def test_show
    get :show, {:id => practitioners(:sav).permalink}, {:client_id => clients(:cyrille).id }
    assert_template 'show'
  end
    
  def test_show_not_logged_in
    get :show, {:id => practitioners(:sav).permalink}
    assert_redirected_to lookup_form_url 
  end
    
  def test_show_not_logged_in_with_email
    client = Factory(:client)
    get :show, {:id => practitioners(:sav).permalink, :email => client.email}
    assert_redirected_to login_phone_url(:login => client.email)
  end
    
  def test_show_pro
    get :show, {:id => practitioners(:sav).permalink}, {:pro_id => practitioners(:sav).id }
    assert_template 'show'
  end
  
end
