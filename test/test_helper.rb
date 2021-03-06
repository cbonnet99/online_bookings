ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  def date_after_24_hours
    date = 1.day.from_now
    if date.strftime("%H").to_i >= Booking::DEFAULT_START_TIME
      date = 2.days.from_now
    end
    return date    
  end

  def date_within_week
    date = Time.zone.now
    distance_to_next_sunday = 7 - date.wday
    if distance_to_next_sunday > 5
      days = -rand(distance_to_next_sunday)
    else
      days = rand(distance_to_next_sunday)
    end
    date = date.advance(:days => days)
  end
  
  def date_within_24_hours
    date = 1.day.from_now
    if date.strftime("%H").to_i < Booking::DEFAULT_START_TIME
      date = Time.zone.now
    end
    return date    
  end
      
	def assert_valid_json(json)	  
	  if json.match(/\{\s*\{/)
      raise "Invalid JSON (two consecutive brackets: {{): #{json}"
	  end
      if json.match(/:\s*\,/)
        raise "Invalid JSON (a colon followed by a comma): #{json}"
      end
      if json.match(/\{\s*,/)
        raise "Invalid JSON (a bracket followed by a comma): #{json}"
      end
		begin
			ActiveSupport::JSON.decode(json)
		rescue ActiveSupport::JSON::ParseError
			raise "Invalid JSON: #{json}"
		end
	end

end
