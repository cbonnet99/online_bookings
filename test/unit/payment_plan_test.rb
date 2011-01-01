require File.dirname(__FILE__) + '/../test_helper'

class PaymentPlanTest < ActiveSupport::TestCase
  def test_price_display_fr
    plan = payment_plans(:fr_basic)
    assert_equal "39.95 EUR", plan.price_display
  end
  def test_price_display_nz
    plan = payment_plans(:nz_basic)
    assert_equal "$39.95", plan.price_display
  end
end
