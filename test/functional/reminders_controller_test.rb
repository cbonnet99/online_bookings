require File.dirname(__FILE__) + '/../test_helper'

class RemindersControllerTest < ActionController::TestCase
  def test_index
    pro = Factory(:practitioner)
    get :index, {}, {:pro_id => pro.id}
    assert_response :success
  end

  def test_index_past
    pro = Factory(:practitioner)
    get :index_past, {}, {:pro_id => pro.id}
    assert_response :success
  end

end
