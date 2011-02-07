require File.dirname(__FILE__) + '/../test_helper'

class ApplicationHelperTest < ActiveSupport::TestCase
  include ApplicationHelper
  
  def test_link_for_locale_localhost_no_existing_locale
    new_url = link_for_locale("http://localhost:3000/practitioners/new", :en)
    assert_equal("http://en.localhost:3000/practitioners/new", new_url)
  end
  
  def test_link_for_locale_localhost
    new_url = link_for_locale("http://en.localhost:3000/practitioners/new", :fr)
    assert_equal("http://fr.localhost:3000/practitioners/new", new_url)
  end
  
  def test_link_for_locale_www
    new_url = link_for_locale("http://www.colibriapp.com/practitioners/new", :en)
    assert_equal("http://en.colibriapp.com/practitioners/new", new_url)
  end
  
  def test_link_for_locale_no_subdomain
    new_url = link_for_locale("http://colibriapp.com/practitioners/new", :en)
    assert_equal("http://en.colibriapp.com/practitioners/new", new_url)
  end
  
end