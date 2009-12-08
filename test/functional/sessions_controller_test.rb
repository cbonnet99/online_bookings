require File.dirname(__FILE__) + '/../test_helper'

class SessionsControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_template 'new'
  end

  # def test_create
  #   sav = practitioners(:sav)
  #   session[:return_to] = practitioner_url(sav)
  #   post :create, {:client => {:email => "cbonnnet@test.com", :phone_prefix => "021", :phone_suffix => "12345678" }}
  #   assert_nil flash[:error]
  #   assert_not_nil flash[:notice]
  #   assert_redirected_to practitioner_url(sav)
  # end
  
end
