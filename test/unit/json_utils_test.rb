require File.dirname(__FILE__) + '/../test_helper'

class JsonUtilsTest < ActiveSupport::TestCase
  
  def test_remove_timezone
    hash = Hash.new
    hash["starts_at"] = "Thu May 06 2010 09:00:00 GMT+0800 (PHT)"
    new_hash = JsonUtils.remove_timezone(hash)
    assert_equal "Thu May 06 2010 09:00:00", new_hash["starts_at"]
  end
  
  def test_remove_timezone_crazy
    hash = Hash.new
    hash["starts_at"] = "Thu May 06 2010 09:00:00 GMT+0800 (Whatever)"
    new_hash = JsonUtils.remove_timezone(hash)
    assert_equal "Thu May 06 2010 09:00:00", new_hash["starts_at"]
  end
  
end