require 'test_helper'

class ClientsControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Client.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    Client.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to root_url
    assert_equal assigns['client'].id, session['client_id']
  end
end
