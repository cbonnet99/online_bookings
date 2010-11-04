require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < ActiveSupport::TestCase
  def test_default_country
    default_country = Factory(:country, :is_default => true)
    other_country = Factory(:country, :is_default => false, :country_code => "NZ")
    assert_equal default_country, Country.default_country
  end
end
