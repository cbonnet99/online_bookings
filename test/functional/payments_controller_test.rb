require File.dirname(__FILE__) + '/../test_helper'

class PaymentsControllerTest < ActionController::TestCase
  def test_new
    pro = Factory(:practitioner, :country => countries(:fr))
    get :new, {}, :pro_id  => pro.id
    assert_not_nil assigns(:default_plan)
    assert !assigns(:plans).blank?
    assert_response :success
  end
  
  def test_create_success
    pro = Factory(:practitioner, :country => countries(:fr), :state => "test_user")
    assert pro.test_user?
    assert_nil pro.payment_plan
    assert_equal 0, pro.sms_credit
    pro.create_sample_data!
    assert pro.bookings.size > 0
    payment_plan = payment_plans(:fr_basic)
    assert_not_nil payment_plan
    assert payment_plan.sms_credit > 0
    expires = Time.now.advance(:year => 1 )
    
    post :create, {:payment => {:first_name => pro.first_name, :last_name => pro.last_name,
      :card_number => "1", :card_verification => "123", :payment_plan => payment_plan, 
      "card_expires_on(1i)" => expires.year.to_s, "card_expires_on(2i)" => expires.month.to_s,
      "card_expires_on(3i)" => expires.day.to_s, :address1 => "1, rue de la Fontaine",
      :city => "Villefranche" } }, :pro_id  => pro.id
      
    assert_not_nil assigns(:payment)
    assert_equal "EUR", assigns(:payment).currency    
    assert_equal 0, assigns(:payment).errors.size, "Unexpected errors: #{assigns(:payment).errors.full_messages.to_sentence}"
    assert_not_nil assigns(:payment).amount
    assert_redirected_to practitioner_url(pro.permalink)
    assert assigns(:payment).completed?
    pro.reload
    assert_equal 0, pro.bookings.size, "The sample data should have been deleted"
    assert pro.active?
    assert_not_nil pro.payment_plan
    assert_equal payment_plan.sms_credit, pro.sms_credit
  end

  def test_create_error
    pro = Factory(:practitioner)
    expires = Time.now.advance(:year => 1 )
    post :create, {:payment => {:first_name => pro.first_name, :last_name => pro.last_name,
      :card_number => "2", :card_verification => "123",
      "card_expires_on(1i)" => expires.year.to_s, "card_expires_on(2i)" => expires.month.to_s,
      "card_expires_on(3i)" => expires.day.to_s, :address1 => "1, rue de la Fontaine",
      :city => "Villefranche" } }, :pro_id  => pro.id
    assert_not_nil assigns(:payment)
    assert_response :success
  end
end
