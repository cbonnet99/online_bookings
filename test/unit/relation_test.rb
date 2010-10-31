require File.dirname(__FILE__) + '/../test_helper'

class PractitionerTest < ActiveSupport::TestCase
  fixtures :all
  
  def test_bookings
    old_size = Relation.all.size
    b = Factory(:booking)
    b2 = Factory(:booking, :client_id => b.client_id, :practitioner_id => b.practitioner_id)
    assert_equal old_size+1, Relation.all.size
    b2.destroy
    assert_equal old_size+1, Relation.all.size, "Relation should have changed: there is still 1 booking between these 2 people"
    b.destroy
    assert_equal old_size+1, Relation.all.size, "Relation should be preserved, even when no booking is left"
  end
  
  def test_with_existing_relation
    c = Factory(:client)
    p = Factory(:practitioner)
    Relation.create(:client => c, :practitioner => p )
    old_size = Relation.all.size
    b = Factory(:booking, :client => c, :practitioner => p)
    assert_equal old_size, Relation.all.size
  end
end