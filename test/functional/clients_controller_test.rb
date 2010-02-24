require File.dirname(__FILE__) + '/../test_helper'

class ClientsControllerTest < ActionController::TestCase

  def test_update
    client = Factory(:client)
    post :update, {:client => {:email => "newaddress@test.com", :phone_prefix => "027", :phone_suffix => "123456"} }, {:client_id => client.id }
    assert_redirected_to edit_client_url(client)
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    client.reload
    assert_equal "newaddress@test.com", client.email
    assert_equal "027-123456", client.phone
  end

  def test_update_error
    client = Factory(:client)
    post :update, {:client => {:email => "", :phone_prefix => "027", :phone_suffix => "123456"} }, {:client_id => client.id }
    assert_response :success
    assert_nil flash[:notice]
    assert_not_nil flash[:error]
    client.reload
    assert !client.email.blank?
  end

  def test_lookup_client_exists
    cyrille = clients(:cyrille)
    post :lookup, {:client => {:email => cyrille.email} }
    assert_redirected_to login_phone_url(:login => cyrille.email)    
  end

  def test_lookup_client_doesnt_exist
    post :lookup, {:client => {:email => "test@test.com"} }
    assert_redirected_to signup_url(:email => "test@test.com")    
  end

  def test_lookup_invalid_email
    post :lookup, {:client => {:email => "BLA"} }
    assert_redirected_to lookup_form_url(:email => "BLA")
    assert_not_nil flash[:error]
  end

  def test_create_existing_client
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    session[:return_to] = practitioner_url(sav)
    post :create, {:client => {:email => cyrille.email, :phone_prefix => cyrille.phone_prefix, :phone_suffix => cyrille.phone_suffix }}
    assert_not_nil flash[:error]
    client = assigns(:client)
    assert_not_nil client
    assert !client.errors.blank?, "There should be some errors on the client, as the email address already exists"
  end

  def test_create
    sav = practitioners(:sav)
    session[:return_to] = practitioner_url(sav)
    post :create, {:client => {:email => "cbonnnet@test.com", :phone_prefix => "021", :phone_suffix => "12345678" }}
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_redirected_to practitioner_url(sav)
  end

  def test_lookup_form
    get :lookup_form
    assert_response :success
    assert_template 'lookup_form'
  end

  def test_login
    cyrille = clients(:cyrille)
    sav = practitioners(:sav)
    last4_digits = cyrille.phone_suffix[-4..cyrille.phone_suffix.length]
    session[:return_to] = practitioner_url(sav)
    post :login, {:login => cyrille.email, :phone_last4digits => last4_digits }
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_redirected_to practitioner_url(sav)
  end
  
  def test_login_phone
    get :login_phone, :login => clients(:cyrille).email 
    assert_template 'login_phone'
  end
  
  def test_login_phone_no_number
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
		
    c = Factory(:client)
    get :login_phone, :login => c.email
    assert_not_nil flash[:warning]
    assert_redirected_to root_url
    
    assert_equal 1, ActionMailer::Base.deliveries.size, "One email should have been sent with a reset link"
  end
    
  def test_login_wrong_numbers
    cyrille = clients(:cyrille)
    post :login, :login => cyrille.email, :phone_last4digits => "1234"
    assert_not_nil flash[:error]
    assert_redirected_to login_phone_url(:login => cyrille.email)
  end
  
end
