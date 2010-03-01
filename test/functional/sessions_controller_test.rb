require File.dirname(__FILE__) + '/../test_helper'

class SessionsControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_template 'new'
  end

  def test_create
    sav = practitioners(:sav)
    session[:return_to] = practitioner_url(sav)
    post :create, {:email => sav.email, :password => "secret" }
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_not_nil session[:pro_id]
    assert_redirected_to practitioner_url(sav, :tab => "calendar")    
  end    
  
  def test_create_megan
    megan = practitioners(:megan)
    session[:return_to] = practitioner_url(megan)
    post :create, {:email => megan.email, :password => "secret" }
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_not_nil session[:pro_id]
    assert_redirected_to practitioner_url(megan, :tab => "calendar")    
  end    
  
end
