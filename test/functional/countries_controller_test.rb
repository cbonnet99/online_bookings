require File.dirname(__FILE__) + '/../test_helper'

class CountriesControllerTest < ActionController::TestCase
  def test_mobile_phone_prefixes
    get :mobile_phone_prefixes, :id => countries(:fr).id 
    assert_response :success
    assert !@response.body.blank?
    assert_valid_json(@response.body)    
  end
  def test_landline_phone_prefixes
    get :landline_phone_prefixes, :id => countries(:fr).id 
    assert_response :success
    assert !@response.body.blank?
    assert_valid_json(@response.body)    
  end
end
