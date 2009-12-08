require File.dirname(__FILE__) + '/../test_helper'

class PractitionersControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_template 'new'
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
end
