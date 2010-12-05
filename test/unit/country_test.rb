require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < ActiveSupport::TestCase

  def test_recreate_test_user
    france = countries(:fr)
    assert_equal 0, france.practitioners.test_user.size
    france.recreate_test_user(2, 5)
    assert_equal 1, france.practitioners.test_user.size, "One demo practitioner should have been created"
    france.recreate_test_user(2, 5)
    assert_equal 1, france.practitioners.test_user.size, "There should still only be one demo practitioner: it should have been deleted and then recreated"
  end


  def test_default_country
    assert_equal countries(:fr), Country.default_country
  end
  
  def test_available_countries
    assert_equal [countries(:fr), countries(:nz)], Country.available_countries    
  end
  
  def test_mobile_phone_prefixes
    assert_equal ["06","07"], countries(:fr).mobile_phone_prefixes
  end

  def test_landline_phone_prefixes
    assert_equal ["01","02","03","04","05","08","09"], countries(:fr).landline_phone_prefixes
  end
  
  def test_lowercase_locale
    assert_equal "fr", countries(:fr).lowercase_locale
  end
end
