require File.dirname(__FILE__) + '/../test_helper'

class BookingsControllerTest < ActionController::TestCase

  def test_show
    pro = Factory(:practitioner)
    booking = Factory(:booking, :practitioner => pro)
    
    get :show, {:id => booking.id}, {:pro_id => pro.id}
    assert_response :success
  end

  def test_show_unautorized
    pro = Factory(:practitioner)
    booking = Factory(:booking, :practitioner => pro)
    
    get :show, {:id => booking.id}
    assert_redirected_to login_url
  end

  def test_cancel_text
    booking = Factory(:booking, :state => "unconfirmed")
    pro = booking.practitioner
    post :cancel_text, {:id => booking.id}, {:pro_id => pro.id}
    assert_response :success
    assert !@response.body.blank?, "No cancellation text was returned"
    name_regex = Regexp.new(booking.practitioner.name)
    assert_match name_regex, @response.body
    assert_no_match %r{<br/>}, @response.body, "HTML BRs should have been replaced by \n"
  end

  def test_client_confirm
    booking = Factory(:booking, :state => "unconfirmed")
    assert_not_nil booking.confirmation_code
    post :client_confirm, {:id => booking.id, :confirmation_code => booking.confirmation_code}
    assert_response :success
    assert_not_nil flash[:notice]
    assert_match %r{#{booking.practitioner.name}}, flash[:notice]
    booking.reload
    assert booking.confirmed?
    assert_not_nil booking.confirmed_at
  end

  def test_client_confirm_already_confirmed
    booking = Factory(:booking, :state => "confirmed")
    assert_not_nil booking.confirmation_code
    post :client_confirm, {:id => booking.id, :confirmation_code => booking.confirmation_code}
    assert_response :success
    assert_not_nil flash[:notice]
    assert_no_match %r{#{booking.practitioner.name}}, flash[:notice]
    booking.reload
    assert booking.confirmed?
  end

  def test_pro_confirm
    booking = Factory(:booking, :state => "unconfirmed")
    pro = booking.practitioner
    post :pro_confirm, {:format => "json", :id => booking.id}, {:pro_id  => pro.id}
    assert_response :success
    assert_not_nil flash[:notice]
    assert_match %r{#{booking.client.name}}, flash[:notice]
    booking.reload
    assert booking.confirmed?
    assert_not_nil booking.confirmed_at
  end

  def test_client_cancel
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking, :state => "unconfirmed")
    assert_not_nil booking.confirmation_code
    post :client_cancel, {:id => booking.id, :confirmation_code => booking.confirmation_code}
    assert_response :success
    booking.reload
    assert booking.cancelled_by_client?
    assert_equal old_mail_size, ActionMailer::Base.deliveries.size, "No email should have been sent, as the client cancelled this booking"
  end

  def test_pro_cancel_dont_send_email
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking, :state => "unconfirmed")
    pro = booking.practitioner
    post :pro_cancel, {:format => "json", :id => booking.id, :send_email => false}, {:pro_id => pro.id}
    assert_response :success
    assert_nil flash[:error]
    booking.reload
    assert booking.cancelled_by_pro?
    assert_equal old_mail_size, ActionMailer::Base.deliveries.size, "No email should have been sent, as this booking is still in its grace period"
  end

  def test_pro_cancel_send_email
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking, :state => "unconfirmed")
    pro = booking.practitioner
    post :pro_cancel, {:format => "json", :id => booking.id, :send_email => true}, {:pro_id => pro.id}
    assert_response :success
    assert_nil flash[:error]
    booking.reload
    assert booking.cancelled_by_pro?
    assert_equal old_mail_size+1, ActionMailer::Base.deliveries.size, "An email to the client should have been sent"
  end

  def test_pro_cancel_send_email_with_custom_text
    custom_text = "Hello Dad\nIt's me"
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking, :state => "unconfirmed")
    
    pro = booking.practitioner
    post :pro_cancel, {:format => "json", :id => booking.id, :send_email => true, :cancellation_text => custom_text}, {:pro_id => pro.id}
    assert_response :success
    assert_nil flash[:error]
    booking.reload
    assert booking.cancelled_by_pro?
    assert_equal old_mail_size+1, ActionMailer::Base.deliveries.size, "An email to the client should have been sent"
    last_email = ActionMailer::Base.deliveries.last
    assert_equal custom_text.gsub(/\n/, "<br/>"), last_email.body, "The email should contain the custom text, with HTML BRs"
  end

  def test_destroy_in_grace_period
    new_booking = Factory(:booking, :state => "in_grace_period")
    pro = new_booking.practitioner
    old_size = Booking.all.size
    post :destroy, {:practitioner_id => pro.permalink, :format => "json", :id => new_booking.id},
     {:pro_id => pro.id }
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size-1, Booking.all.size
  end

  def test_destroy_confirmed
    new_booking = Factory(:booking, :state => "confirmed")
    pro = new_booking.practitioner
    old_size = Booking.all.size
    assert_raise ActiveRecord::RecordNotSaved do
      post :destroy, {:practitioner_id => pro.permalink, :format => "json", :id => new_booking.id},
        {:pro_id => pro.id }
    end
    assert_equal old_size, Booking.all.size
  end

  def test_create_no_client
    pro = Factory(:practitioner)
    post :create, {:format => "json", :booking => {:starts_str => Booking.starts_str_builder(1.day.from_now), :ends_str => Booking.ends_str_builder(1.day.from_now)} }, {:pro_id => pro.id }
    assert_response :success
    assert_not_nil flash[:error], "Flash was: #{flash.inspect}"
    assert_equal 1, assigns(:booking).errors.size, "Errors were: #{assigns(:booking).errors.full_messages.to_sentence}"
  end
  
  def test_update_client_as_pro
    sav = practitioners(:sav)
    cyrille = clients(:cyrille_sav)
    kartini = clients(:kartini_sav)
    cyrille_sav = Factory(:booking, :client => cyrille, :practitioner => sav, :created_at => 10.minutes.ago, :state => "in_grace_period")
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:client_id => kartini.id, :client_phone_prefix => "029",  :client_phone_suffix => "2873129731", :client_email  => "kthom@test.com" } }, {:pro_id => sav.id }
    assert_response :success
    assert_valid_json(@response.body)
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    cyrille_sav.reload
    kartini.reload
    assert_equal kartini.default_name, cyrille_sav.name
    assert_equal kartini.id, cyrille_sav.client_id
    assert_equal "029", kartini.phone_prefix
    assert_equal "2873129731", kartini.phone_suffix
    assert_equal "kthom@test.com", kartini.email
  end

  def test_update_client_as_pro_error
    sav = practitioners(:sav)
    cyrille = clients(:cyrille_sav)
    kartini = clients(:kartini_sav)
    cyrille_sav = Factory(:booking, :client => cyrille, :practitioner => sav, :created_at => 10.minutes.ago, :state => "in_grace_period")
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:client_id => kartini.id, :client_phone_prefix => "029",  :client_phone_suffix => "28", :client_email  => "kthom@test.com" } }, {:pro_id => sav.id }
    assert_response :success
    assert_valid_json(@response.body)
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  def test_update_in_grace_period
    mail_size = UserEmail.all.size    
    booking = Factory(:booking, :state => "in_grace_period", :created_at => 20.minutes.ago)
    pro = booking.practitioner
    new_client = Factory(:client)
    post :update, {:practitioner_id => pro.permalink, :format => "json", :id => booking.id, 
                  :booking => {:client_id => new_client.id } }, {:pro_id => pro.id }
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    booking.reload
    assert_equal new_client.default_name, booking.name
    assert_equal new_client.id, booking.client_id
    assert_equal mail_size, UserEmail.all.size, "No email should have been sent as the booking is in grace period"
  end

  def test_update_outside_of_grace_period
    booking = Factory(:booking, :state => "unconfirmed", :created_at => 2.hours.ago)
    pro = booking.practitioner
    old_client = booking.client
    new_client = Factory(:client)
    post :update, {:practitioner_id => pro.permalink, :format => "json", :id => booking.id, 
                  :booking => {:client_id => new_client.id } }, {:pro_id => pro.id }
    assert_response :success
    assert_not_nil flash[:error], "An error should have been created, because the booking cannot be modified outside of its grace period"
    assert_nil flash[:notice]
    booking.reload
    assert_equal old_client.default_name, booking.name
    assert_equal old_client.id, booking.client_id
  end

  def test_create_with_prep_time
    mail_size = UserEmail.all.size
    sav = Factory(:practitioner, :prep_before => false, :prep_time_mins => 30)  
    cyrille = Factory(:client, :practitioner => sav)
    old_size = Booking.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:client_id => cyrille.id, :comment => "I'll be on time", 
      :starts_str => Booking.starts_str_builder(1.day.from_now),
      :ends_str => Booking.ends_str_builder(1.day.from_now)}},
      {:pro_id => sav.id }
    # puts @response.body 
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_match %r{#{assigns(:booking).client.name}}, flash[:notice]
    assert_equal old_size+1, Booking.all.size    
    new_booking = assigns(:booking)
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert !new_booking.prep_before
    assert_equal 30, new_booking.prep_time_mins
    assert_equal sav.id, new_booking.practitioner_id
  end

  def test_create_pro_no_client_id
    sav = practitioners(:sav)
    cyrille = clients(:cyrille_sav)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    reminders_size = Reminder.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "Joe Test", :client_email => "joe@test.com", :client_id => "", :comment => "I'll be on time", :booking_type => booking_types(:sav_one_hour), 
      :starts_str => Booking.starts_str_builder(1.day.from_now), :client_phone_prefix => "021", :client_phone_suffix => "4354364",  
      :ends_str => Booking.ends_str_builder(1.day.from_now)}},
      {:pro_id => sav.id }
    # puts @response.body
    assert_response :success
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = assigns(:booking)
    assert_equal "Joe Test", new_booking.client_name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
    new_client = Client.find_by_email("joe@test.com")
    assert_not_nil new_client
    assert_equal sav.id, new_client.practitioner_id
  end

  def test_create_pro_no_client_id_no_email
    sav = practitioners(:sav)
    cyrille = clients(:cyrille_sav)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    reminders_size = Reminder.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "Joe Test", :client_id => "", :comment => "I'll be on time", :booking_type => booking_types(:sav_one_hour), 
      :starts_str => Booking.starts_str_builder(1.day.from_now), :client_phone_prefix => "021", :client_phone_suffix => "4354364",  
      :ends_str => Booking.ends_str_builder(1.day.from_now)}},
      {:pro_id => sav.id }
    # puts @response.body
    assert_response :success
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = assigns(:booking)
    assert_equal "Joe Test", new_booking.client_name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
  end

  def test_create_pro_no_client_id_identical_email_identical_info
    sav = practitioners(:sav)
    cyrille = clients(:cyrille_sav)
    old_name = cyrille.name
    old_email = cyrille.email
    old_phone = cyrille.phone
    old_phone_prefix = cyrille.phone_prefix
    old_phone_suffix = cyrille.phone_suffix
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    reminders_size = Reminder.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => old_name, :client_email => old_email, :client_phone_prefix => old_phone_prefix,
      :client_phone_suffix => old_phone_suffix, :client_id => "", :booking_type => booking_types(:sav_one_hour), 
      :starts_str => Booking.starts_str_builder(1.day.from_now),
      :ends_str => Booking.ends_str_builder(1.day.from_now)}},
      {:pro_id => sav.id }
    # puts @response.body
    assert_response :success
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = assigns(:booking)
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
    cyrille.reload
    assert_equal old_name, cyrille.name
    assert_equal old_phone, cyrille.phone
    assert_equal old_email, cyrille.email
  end

  def test_create_pro
    sav = practitioners(:sav)
    cyrille = clients(:cyrille_sav)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    reminders_size = Reminder.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "undefined", :client_id => cyrille.id, :comment => "I'll be on time", :booking_type => booking_types(:sav_one_hour), 
      :starts_str => Booking.starts_str_builder(1.day.from_now), :ends_str => Booking.ends_str_builder(1.day.from_now)}},
      {:pro_id => sav.id }
    # puts @response.body
    assert_response :success
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = assigns(:booking)
    assert_equal "Cyrille Bonnet", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
  end

  def test_create_pro_longer
    megan = practitioners(:megan)
    cyrille = clients(:cyrille_megan)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    post :create, {:practitioner_id => megan.permalink, :format => "json",
      :booking => {:name => "undefined", :client_id => cyrille.id, :comment => "I'll be on time", :booking_type => booking_types(:megan_two_hour), 
      :starts_str => Booking.starts_str_builder(1.day.from_now),
      :ends_str => Booking.ends_str_builder(1.day.from_now)}},
      {:pro_id => megan.id }
    # puts @response.body
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = assigns(:booking)
    assert_equal "Cyrille Bonnet", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    
    assert_not_nil new_booking.booking_type
  end

  def test_create_pro_no_invite
    sav = practitioners(:sav)
    Time.zone = sav.timezone
    sav.update_attribute(:invite_on_pro_book, false)
    sav.reload
    cyrille = clients(:cyrille_sav)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    sav_one_hour = booking_types(:sav_one_hour)
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "undefined", :client_id => cyrille.id, :comment => "I'll be on time", :booking_type => sav_one_hour, 
      :starts_str => Booking.starts_str_builder(1.day.from_now),
      :ends_str => Booking.ends_str_builder(1.day.from_now)}},
      {:pro_id => sav.id }
    assert_response :success
    # puts @response.body
    assert_valid_json(@response.body)
    assert_not_nil assigns(:booking)
    assert assigns(:booking).errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = assigns(:booking)
    assert_equal "Cyrille Bonnet", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
    assert_equal mail_size, UserEmail.all.size
  end

  def test_index_cal
    sav = practitioners(:sav)
    get :index_cal, {:pub_code => sav.bookings_publish_code, :practitioner_id => sav.permalink, :format => "ics"}
    assert_response :success
    assert_not_nil assigns(:practitioner)
    assert_not_nil assigns(:bookings)
    assert !assigns(:bookings).blank?
  end

  def test_index_cal_bad_pub_code
    sav = practitioners(:sav)
    get :index_cal, {:pub_code => "BAD", :practitioner_id => sav.permalink, :format => "ics"}
    assert_redirected_to root_url
  end

  def test_index
    pro = Factory(:practitioner)
    get :index, {}, {:pro_id => pro.id }
    assert_response :success
  end

  def test_index_json
    pro = practitioners(:sav)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.beginning_of_week,
       :end => Time.zone.now.end_of_week}, {:pro_id => pro.id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 5, assigns(:bookings).size, "Sav should have 0 booking and 5 non-working days, but bookings are: #{assigns(:bookings).to_sentence}"
    assert_match(/state/, @response.body)
  end

  def test_index_sav_self
    pro = practitioners(:sav)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.beginning_of_week, :end => Time.zone.now.end_of_week}, {:pro_id => practitioners(:sav).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 5, assigns(:bookings).size, "Sav should have 0 booking and 5 non-working days, but bookings are: #{assigns(:bookings).to_json}"
  end

  def test_index_sav_own_next_week
    pro = practitioners(:sav)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.end_of_week, :end => Time.zone.now.end_of_week.advance(:days => 7 )}, {:pro_id => practitioners(:sav).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 6, assigns(:bookings).size, "Sav should have 1 booking and 5 non-working day, but bookings are: #{assigns(:bookings).to_json}"
    first_booking = assigns(:bookings).first
    assert !first_booking.read_only?, "The first booking (a booking by a client) should be editable, but it is read only"
    assert_not_equal "Booked", first_booking.name, "The client name for the first booking (a booking by a client) should be visible to the practitioner"
  end  
end
