require File.dirname(__FILE__) + '/../test_helper'

class ClientsControllerTest < ActionController::TestCase

  def test_homepage
    get :homepage
    assert_response :success
  end
  
  def test_index
    pro = Factory(:practitioner)
    get :index, {}, {:pro_id => pro.id}
    assert_response :success
  end
  
  def test_index_not_logged_in
    get :index
    assert_redirected_to login_url
  end
  
  def test_new
    get :new
    assert_response :success
    assert_select "input#client_email"
  end

  def test_destroy
    pro = Factory(:practitioner)
    client = Factory(:client)
    pro.clients << client
    old_size = pro.clients.size
    post :destroy, {:id => client.id }, {:pro_id => pro.id}
    assert_redirected_to practitioner_clients_url(pro.permalink)
    assert_not_nil flash[:notice]
    assert_equal old_size, pro.clients.size+1
  end

  def test_update
    client = Factory(:client)
    post :update, {:client => {:phone_prefix => "027", :phone_suffix => "123456", :email => "newaddress@test.com"} }, {:client_id => client.id }
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

  def test_create_multiple_with_name
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = sav.clients.size
    post :create, {:emails => "\"David Savage\" <cbgt@test.com>, \"Cyrille Test\" <#{cyrille.email}>" }, {:pro_id => sav.id}
    assert_redirected_to practitioner_clients_url(sav.permalink)
    assert_equal old_size+1, sav.clients.size, "Only 1 client should be added, as Cyrille is already a client"
  end

  def test_create_multiple
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = sav.clients.size
    post :create, {:emails => "cbgt@test.com, #{cyrille.email}" }, {:pro_id => sav.id}
    assert_redirected_to practitioner_clients_url(sav.permalink)
    assert_equal old_size+1, sav.clients.size, "Only 1 client should be added, as Cyrille is already a client"
  end

  def test_create_multiple_with_email
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = sav.clients.size
    
    old_mail_size = ActionMailer::Base.deliveries.size
    
    post :create, {:emails => "cbgt@test.com, #{cyrille.email}", :send_email => true, :email_text => "Hello,\n\nThis is my new booking site: ", :email_signoff => "Regards,"  }, {:pro_id => sav.id}
    assert_redirected_to practitioner_clients_url(sav.permalink)
    assert_equal old_size+1, sav.clients.size, "Only 1 client should be added, as Cyrille is already a client"
    assert_equal old_mail_size+1, ActionMailer::Base.deliveries.size
    last_email = ActionMailer::Base.deliveries.last
    assert_equal ["cbgt@test.com"], last_email.to
    assert_equal [sav.email], last_email.from
    assert_match %r{Hello,<br/><br/>}, last_email.body
  end

  def test_create_multiple_error
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = sav.clients.size
    post :create, {:emails => "cbgt@test.com test #{cyrille.email}" }, {:pro_id => sav.id}
    assert_redirected_to new_practitioner_client_url(sav.permalink, :emails => "cbgt@test.com test #{cyrille.email}")
    assert_not_nil flash[:error]
    assert_equal old_size, sav.clients.size
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
    assert_nil flash[:error], "Flash: #{flash.inspect}"
    assert_not_nil flash[:notice], "Flash: #{flash.inspect}"
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
