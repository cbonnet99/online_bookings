require File.dirname(__FILE__) + '/../test_helper'

class RoutingTest < ActionController::TestCase

  def test_routes
    assert_generates "/practitioners/bla/bookings/123.json", { :controller => "bookings", :action => "destroy", :practitioner_id => "bla", :id => "123", :format => "json"}
    assert_generates "/practitioners/bla/bookings/123.json", { :controller => "bookings", :action => "update", :practitioner_id => "bla", :id => "123", :format => "json" }
    assert_generates "/practitioners/change", { :controller => "practitioners", :action => "change"}
    assert_generates "/clients/123/edit", { :controller => "clients", :action => "edit", :id => "123" }
  end
  
end