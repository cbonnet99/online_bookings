require File.dirname(__FILE__) + '/../test_helper'

class PractitionersControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_template 'new'
  end

  def test_create
    old_size = Practitioner.all.size
    post :create, :practitioner => {:email => "cb@test.com", :password => "blabla", :password_confirmation => "blabla", :working_hours => "9-12,13-18" }
    assert_not_nil assigns(:practitioner)
    assert assigns(:practitioner).errors.blank?, "Errors found: #{assigns(:practitioner).errors.full_messages.  to_sentence}"
    assert_nil flash[:error]
    assert_equal old_size+1, Practitioner.all.size
  end

  def test_edit_selected
    get :edit_selected
    assert_template 'edit_selected'
  end
  
  def test_update_selected
    sav = practitioners(:sav)
    post :update_selected, :practitioner_id => sav.id
    assert_redirected_to sav
  end
  
  def test_show
    get :show, {:practitioner_permalink => practitioners(:sav).permalink}, {:client_id => clients(:cyrille).id }
    assert_template 'show'
  end
  
  def test_show_pro
    get :show, {:practitioner_permalink => practitioners(:sav).permalink}, {:pro_id => practitioners(:sav).id }
    assert_template 'show'
  end
  
end
