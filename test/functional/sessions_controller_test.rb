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
    assert_redirected_to practitioner_url(sav)
    
  end
  
end
