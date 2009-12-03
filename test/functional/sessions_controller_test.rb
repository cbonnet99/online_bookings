require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Client.stubs(:authenticate).returns(nil)
    post :create
    assert_template 'new'
    assert_nil session['client_id']
  end
  
  def test_create_valid
    Client.stubs(:authenticate).returns(Client.first)
    post :create
    assert_redirected_to root_url
    assert_equal Client.first.id, session['client_id']
  end
end
