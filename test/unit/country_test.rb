require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < ActiveSupport::TestCase
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
