require File.dirname(__FILE__) + '/../test_helper'

class RoutingTest < ActionController::TestCase

  def test_routes
    # assert_recognizes { :controller => "bookings", :action => "update", :practitioner_id => "bla", :id => "123", :format => "json" }, "/practitioners/bla/bookings/123.json", {:method => :put }
    assert_generates "/countries/mobile_phone_prefixes/123", { :controller => "countries", :action => "mobile_phone_prefixes", :id => "123"}
    assert_generates "/bookings/123/cancel_text", { :controller => "bookings", :action => "cancel_text", :id => "123"}
    assert_generates "/bookings/123/pro_confirm.json", { :controller => "bookings", :action => "pro_confirm", :id => "123", :format => "json"}
    assert_generates "/country_select.js", { :controller => "clients", :action => "country_select", :format => "js"}
    assert_generates "/practitioners/bla/bookings/123.json", { :controller => "bookings", :action => "destroy", :practitioner_id => "bla", :id => "123", :format => "json" }
    assert_generates "/practitioners/bla/bookings/123.json", { :controller => "bookings", :action => "update", :practitioner_id => "bla", :id => "123", :format => "json" }
    assert_generates "/practitioners/bla/bookings/czb123", { :controller => "bookings", :action => "index_cal", :practitioner_id => "bla", :pub_code => "czb123", :format => "ics"}
    assert_generates "/practitioners/bla/reset_ical_sharing", { :controller => "practitioners", :action => "reset_ical_sharing", :id => "bla"}
    assert_generates "/practitioners/bla/bookings/123.json", { :controller => "bookings", :action => "destroy", :practitioner_id => "bla", :id => "123", :format => "json"}
    assert_generates "/practitioners/bla/bookings/123.json", { :controller => "bookings", :action => "update", :practitioner_id => "bla", :id => "123", :format => "json" }
    assert_generates "/practitioners/change", { :controller => "practitioners", :action => "change"}
    assert_generates "/clients/123/edit", { :controller => "clients", :action => "edit", :id => "123" }
  end
  
end