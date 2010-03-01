require File.dirname(__FILE__) + '/../test_helper'

class PractitionersControllerTest < ActionController::TestCase
  
  def test_new
    get :new
    assert_template 'new'
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
    post :create, :practitioner => {:email => "cb@test.com", :phone => "021 221312312", :first_name => "Joe",
       :last_name => "Test", :password => "blabla", :password_confirmation => "blabla",
        :working_day_monday => true, :working_hours => "9-12,13-18" }
    assert_not_nil assigns(:practitioner)
    assert assigns(:practitioner).errors.blank?, "Errors found: #{assigns(:practitioner).errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_equal old_size+1, Practitioner.all.size
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
    
  def test_show_pro
    get :show, {:id => practitioners(:sav).permalink}, {:pro_id => practitioners(:sav).id }
    assert_template 'show'
  end
  
end
