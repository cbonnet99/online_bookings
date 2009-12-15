require File.dirname(__FILE__) + '/../test_helper'

class TimeUtilsTest < ActiveSupport::TestCase  
  
  def test_round_previous_hour
    assert_equal "8", TimeUtils.round_previous_hour("8:30")
    assert_equal "8", TimeUtils.round_previous_hour("8:45")
    assert_equal "8", TimeUtils.round_previous_hour("8:00")
    assert_equal "8", TimeUtils.round_previous_hour("8")
    assert_equal "17", TimeUtils.round_previous_hour("17:30")
    assert_equal "17", TimeUtils.round_previous_hour("17:45")
    assert_equal "17", TimeUtils.round_previous_hour("17:00")
    assert_equal "17", TimeUtils.round_previous_hour("17")
  end
  
  def test_round_next_hour
    assert_equal "9", TimeUtils.round_next_hour("8:30")
    assert_equal "9", TimeUtils.round_next_hour("8:45")
    assert_equal "9", TimeUtils.round_next_hour("8:00")
    assert_equal "8", TimeUtils.round_next_hour("8")
    assert_equal "18", TimeUtils.round_next_hour("17:30")
    assert_equal "18", TimeUtils.round_next_hour("17:45")
    assert_equal "18", TimeUtils.round_next_hour("17:00")
    assert_equal "17", TimeUtils.round_next_hour("17")
  end
  
end
