require File.dirname(__FILE__) + '/../test_helper'

class RoutingTest < ActionController::TestCase

  def test_routes
    assert_generates "/practitioners/change", { :controller => "practitioners", :action => "change"}
  end
  
end