require File.dirname(__FILE__) + '/../test_helper'

class PractitionersControllerTest < ActionController::TestCase

  def test_new
    get :new
    assert_template 'new'
    assert_not_nil assigns(:practitioner)
    france = Country.find_by_country_code("FR")
    assert_equal france.id, assigns(:practitioner).country_id
    assert_select "input[type=password]"
    assert_select "input[id=practitioner_sample_data]"
  end

  def test_new_paying
    get :new, :paying => true 
    assert_template 'new'
    assert_not_nil assigns(:practitioner)
    france = Country.find_by_country_code("FR")
    assert_equal france.id, assigns(:practitioner).country_id
    assert_select "input[type=password]"
    assert_select "input[id=practitioner_sample_data]", :count => 0 
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

  def test_create_paying
    old_size = Practitioner.all.size
    france = countries(:fr)
    post :create, :paying => true, :practitioner => {:sample_data => false, :email => "cb@test.com", :phone_prefix => "06", :phone_suffix => "221312312", :first_name => "Joe",
       :last_name => "Test", :password => "blabla", :password_confirmation => "blabla",
        :working_day_monday => "1", :lunch_break => true, :start_time1 => 9, :end_time1  => 12, :start_time2 => 13, :end_time2 => 18, :country_id  => france.id }
    assert_redirected_to new_payment_url 
    assert_not_nil assigns(:practitioner)
    assert_equal 0, assigns(:practitioner).errors.size, "There are unexpected errors on new pro: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_not_nil assigns(:practitioner)
    assert assigns(:practitioner).errors.blank?, "Errors found: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_equal "1", assigns(:practitioner).working_days
    assert_not_nil assigns(:practitioner).permalink
    assert assigns(:practitioner).lunch_break?
    assert_equal france.default_timezone, assigns(:practitioner).timezone
    assert_equal 0, assigns(:practitioner).bookings.size, "No sample data should be created"
    assert_equal "06", assigns(:practitioner).phone_prefix
    assert_equal "221312312", assigns(:practitioner).phone_suffix
    assert_nil flash[:error]
    assert_equal old_size+1, Practitioner.all.size    
  end

  def test_create_with_sample_data
    old_size = Practitioner.all.size
    france = countries(:fr)
    post :create, :practitioner => {:sample_data => true, :email => "cb@test.com", :phone_prefix => "06", :phone_suffix => "221312312", :first_name => "Joe",
       :last_name => "Test", :password => "blabla", :password_confirmation => "blabla",
        :working_day_monday => "1", :lunch_break => true, :start_time1 => 9, :end_time1  => 12, :start_time2 => 13, :end_time2 => 18, :country_id  => france.id }
    assert_not_nil assigns(:practitioner)
    assert_equal 0, assigns(:practitioner).errors.size, "There are unexpected errors on new pro: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_redirected_to waiting_sample_data_practitioner_url(assigns(:practitioner).permalink)
    assert_not_nil assigns(:practitioner)
    assert assigns(:practitioner).errors.blank?, "Errors found: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_equal "1", assigns(:practitioner).working_days
    assert_not_nil assigns(:practitioner).permalink
    assert assigns(:practitioner).lunch_break?
    assert_equal france.default_timezone, assigns(:practitioner).timezone
    assert_equal 0, assigns(:practitioner).bookings.size, "No sample data should be created"
    assert_equal "06", assigns(:practitioner).phone_prefix
    assert_equal "221312312", assigns(:practitioner).phone_suffix    
    assert_nil flash[:error]
    assert_equal old_size+1, Practitioner.all.size
  end

  def test_create_sample_data
    pro = Factory(:practitioner, :state => "test_user", :country => countries(:fr) )
    old_size = pro.bookings.size
    post :create_sample_data, {}, {:pro_id => pro.id}
    assert_response :success
    pro.reload
    #15 bookings in the past + 15 in the future = 30 bookings
    assert_equal old_size+30, pro.bookings.size
  end
  
  def test_waiting_sample_data
    pro = Factory(:practitioner, :country => countries(:fr) )
    get :waiting_sample_data, {}, {:pro_id => pro.id}
    assert_response :success
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

  def test_edit
    pro = Factory(:practitioner)

    get :edit, {}, {:pro_id => pro.id}
    
    assert_response :success
    assert_not_nil assigns(:practitioner)
    assert_select "input[type=password]", :count => 0 
    assert_select "input[id=practitioner_sample_data]", :count => 0 
  end
  
  def test_update
    pro = Factory(:practitioner, :country => countries(:fr))
    
    post :update, {:practitioner => {:first_name => "NewFirst" }}, {:pro_id => pro.id}
    assert_redirected_to :action => "edit"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    pro.reload
    assert_equal "NewFirst", pro.first_name 
  end
  
  def test_update_error
    pro = Factory(:practitioner, :country => countries(:fr))
    
    post :update, {:practitioner => {:first_name => "" }}, {:pro_id => pro.id}
    assert_template "edit"
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
    assert_equal 1, assigns(:practitioner).errors.size
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
