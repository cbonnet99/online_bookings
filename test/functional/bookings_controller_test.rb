require File.dirname(__FILE__) + '/../test_helper'

class BookingsControllerTest < ActionController::TestCase

  def test_confirm
    booking = Factory(:booking)
    assert booking.new_booking?
    assert_not_nil booking.confirmation_code
    post :confirm, {:id => booking.id, :confirmation_code => booking.confirmation_code}
    assert_response :success
    assert_not_nil flash[:notice]
    assert_match %r{#{booking.practitioner.name}}, flash[:notice]
    booking.reload
    assert booking.confirmed?
    assert_not_nil booking.confirmed_at
  end

  def test_client_cancel
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking)
    assert booking.new_booking?
    assert_not_nil booking.confirmation_code
    post :client_cancel, {:id => booking.id, :confirmation_code => booking.confirmation_code}
    assert_response :success
    booking.reload
    assert booking.cancelled_by_client?
    assert_equal old_mail_size, ActionMailer::Base.deliveries.size, "No email should have been sent, as the client cancelled this booking"
  end

  def test_pro_cancel_dont_send_email
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking, :state => "new_booking")
    pro = booking.practitioner
    post :pro_cancel, {:format => "json", :id => booking.id, :send_email => false}, {:pro_id => pro.id}
    assert_response :success
    booking.reload
    assert booking.cancelled_by_pro?
    assert_equal old_mail_size, ActionMailer::Base.deliveries.size, "No email should have been sent, as this booking is still in its grace period"
  end

  def test_pro_cancel_send_email
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking, :state => "new_booking")
    pro = booking.practitioner
    post :pro_cancel, {:format => "json", :id => booking.id, :send_email => true}, {:pro_id => pro.id}
    assert_response :success
    booking.reload
    assert booking.cancelled_by_pro?
    assert_equal old_mail_size+1, ActionMailer::Base.deliveries.size, "An email to the client should have been sent"
  end

  def test_pro_cancel_send_email_with_custom_text
    custom_text = "Hello Dad"
    old_mail_size = ActionMailer::Base.deliveries.size    
    booking = Factory(:booking, :state => "new_booking")
    pro = booking.practitioner
    post :pro_cancel, {:format => "json", :id => booking.id, :send_email => true, :cancellation_text => custom_text}, {:pro_id => pro.id}
    assert_response :success
    booking.reload
    assert booking.cancelled_by_pro?
    assert_equal old_mail_size+1, ActionMailer::Base.deliveries.size, "An email to the client should have been sent"
    last_email = ActionMailer::Base.deliveries.last
    assert_equal custom_text, last_email.body
  end

  #Cyrille (26 September 2010: for the moment, clients cannot destroy bookings)
  # def test_destroy_client
  #   cyrille_sav = bookings(:cyrille_sav)
  #   sav = practitioners(:sav)
  #   cyrille = clients(:cyrille)
  #   old_size = Booking.all.size
  #   post :destroy, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id},
  #    {:client_id => cyrille.id }
  #   assert_response :success
  #   assert_nil flash[:error]
  #   assert_not_nil flash[:notice]
  #   assert_equal old_size-1, Booking.all.size
  # end

  def test_destroy_in_grace_period
    new_booking = Factory(:booking, :state => "new_booking")
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

  def test_create_empty
    post :create, :format => "json" 
    assert_redirected_to flash_url
    assert_not_nil flash[:error]
  end

  def test_create_no_client
    pro = Factory(:practitioner)
    post :create, {:format => "json", :booking => {:starts_at => Time.now.end_of_day.advance(:hours => 14), :ends_at => Time.now.end_of_day.advance(:hours => 15)} }, {:pro_id => pro.id }
    assert_response :success
    assert_not_nil flash[:error], "Flash was: #{flash.inspect}"
    assert_equal 1, assigns(:booking).errors.size, "Errors were: #{assigns(:booking).errors.full_messages.to_sentence}"
  end

  def test_update_no_client
    cyrille_sav = bookings(:cyrille_sav)
    sav = practitioners(:sav)
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:name => "John Denver"} }
    assert_redirected_to flash_url
    assert_not_nil flash[:error]
  end
  
  def test_update_as_client    
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    cyrille_sav = Factory(:booking, :client => cyrille, :practitioner => sav, :created_at => 10.minutes.ago, :state => "new_booking")
    kartini = clients(:kartini)
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:name => "John Denver", :client_id  => kartini.id} }, {:client_id => cyrille.id }
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    cyrille_sav.reload
    assert_equal cyrille.id, cyrille_sav.client_id, "Even though the client tried to cheat and send Kartini's as client_id, it should stay with the currently logged in client (Cyrille)"
    assert_equal "John Denver", cyrille_sav.name
    cyrille.reload
    assert_equal "John Denver", cyrille.name
  end

  def test_update_client_as_pro
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    kartini = clients(:kartini)
    cyrille_sav = Factory(:booking, :client => cyrille, :practitioner => sav, :created_at => 10.minutes.ago, :state => "new_booking")
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
    cyrille = clients(:cyrille)
    kartini = clients(:kartini)
    cyrille_sav = Factory(:booking, :client => cyrille, :practitioner => sav, :created_at => 10.minutes.ago, :state => "new_booking")
    post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
                  :booking => {:client_id => kartini.id, :client_phone_prefix => "029",  :client_phone_suffix => "28", :client_email  => "kthom@test.com" } }, {:pro_id => sav.id }
    assert_response :success
    assert_valid_json(@response.body)
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  def test_update_in_grace_period
    mail_size = UserEmail.all.size    
    booking = Factory(:booking, :state => "new_booking", :created_at => 20.minutes.ago)
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
    booking = Factory(:booking, :state => "new_booking", :created_at => 2.hours.ago)
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


  #Cyrille (7 Sep 2010: no own time option for the moment)
  # def test_update_as_pro_own_time
  #   cyrille_sav = bookings(:cyrille_sav)
  #   sav = practitioners(:sav)
  #   cyrille = clients(:cyrille)
  #   kartini = clients(:kartini)
  #   post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
  #                 :booking => {:client_id => "" } }, {:pro_id => sav.id }
  #   assert_response :success
  #   assert_nil flash[:error]
  #   assert_not_nil flash[:notice]
  #   cyrille_sav.reload
  #   assert_equal sav.own_time_label, cyrille_sav.name
  #   assert_nil cyrille_sav.client_id
  # end

  # def test_update_as_pro_own_time_null
  #   cyrille_sav = bookings(:cyrille_sav)
  #   sav = practitioners(:sav)
  #   cyrille = clients(:cyrille)
  #   kartini = clients(:kartini)
  #   post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
  #                 :booking => {:client_id => "null" } }, {:pro_id => sav.id }
  #   assert_response :success
  #   assert_nil flash[:error]
  #   assert_not_nil flash[:notice]
  #   cyrille_sav.reload
  #   assert_equal sav.own_time_label, cyrille_sav.name
  #   assert_nil cyrille_sav.client_id
  # end
  # 
  # def test_update_as_pro_own_time_comment
  #   cyrille_sav = bookings(:cyrille_sav)
  #   sav = practitioners(:sav)
  #   cyrille = clients(:cyrille)
  #   kartini = clients(:kartini)
  #   post :update, {:practitioner_id => sav.permalink, :format => "json", :id => cyrille_sav.id, 
  #                 :booking => {:client_id => "", :comment => "Hello" } }, {:pro_id => sav.id }
  #   assert_response :success
  #   assert_nil flash[:error]
  #   assert_not_nil flash[:notice]
  #   cyrille_sav.reload
  #   assert_equal "Hello", cyrille_sav.name
  #   assert_nil cyrille_sav.client_id
  # end

  def test_create
    mail_size = UserEmail.all.size
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = Booking.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "Joe Sullivan", :comment => "I'll be on time", :booking_type => booking_types(:sav_one_hour), 
      :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
      :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
      {:client_id => cyrille.id }
    # puts @response.body 
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_match %r{#{assigns(:booking).practitioner.name}}, flash[:notice]
    assert_equal old_size+1, Booking.all.size    
    new_booking = assigns(:booking)
    assert_equal "Joe Sullivan", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
    assert_equal sav.id, new_booking.practitioner_id
    cyrille.reload
    assert_equal "Joe", cyrille.first_name
    assert_equal "Sullivan", cyrille.last_name
    assert_equal mail_size+1, UserEmail.all.size
    new_email = UserEmail.last
    assert_equal sav.email, new_email.to
    assert_match /#{cyrille.name}/, new_email.subject
  end

  def test_create_different_timezone
    mail_size = UserEmail.all.size
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    old_size = Booking.all.size
    Time.zone = "Paris"
    my_starts = Time.zone.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)
    my_day = my_starts.day
    my_month= my_starts.month
    my_year = my_starts.year
    my_hour = my_starts.hour
    
    my_ends = Time.zone.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)
    my_ends_hour = my_ends.hour
    
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "Joe Sullivan", :comment => "I'll be on time", :booking_type => booking_types(:sav_one_hour), 
      :starts_at => "#{my_starts}",
      :ends_at => "#{my_ends}"}},
      {:client_id => cyrille.id }
    # puts @response.body 
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_match %r{#{assigns(:booking).practitioner.name}}, flash[:notice]
    assert_equal old_size+1, Booking.all.size    
    new_booking = assigns(:booking)
    assert_equal "Joe Sullivan", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    Time.zone = sav.timezone
    assert_equal my_day, new_booking.starts_at.day
    assert_equal my_month, new_booking.starts_at.month
    assert_equal my_year, new_booking.starts_at.year
    assert_equal my_hour, new_booking.starts_at.hour
    
    assert_equal my_day, new_booking.ends_at.day
    assert_equal my_month, new_booking.ends_at.month
    assert_equal my_year, new_booking.ends_at.year
    assert_equal my_ends_hour, new_booking.ends_at.hour

    assert_not_nil new_booking.booking_type
    assert_equal sav.id, new_booking.practitioner_id
    cyrille.reload
    assert_equal "Joe", cyrille.first_name
    assert_equal "Sullivan", cyrille.last_name
    assert_equal mail_size+1, UserEmail.all.size
    new_email = UserEmail.last
    assert_equal sav.email, new_email.to
    assert_match /#{cyrille.name}/, new_email.subject
  end

  def test_create_with_prep_time
    mail_size = UserEmail.all.size
    sav = Factory(:practitioner, :prep_before => false, :prep_time_mins => 30)  
    cyrille = clients(:cyrille)
    old_size = Booking.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "Joe Sullivan", :comment => "I'll be on time", 
      :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
      :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
      {:client_id => cyrille.id }
    # puts @response.body 
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_match %r{#{assigns(:booking).practitioner.name}}, flash[:notice]
    assert_equal old_size+1, Booking.all.size    
    new_booking = assigns(:booking)
    assert_equal "Joe Sullivan", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert !new_booking.prep_before
    assert_equal 30, new_booking.prep_time_mins
    assert_equal sav.id, new_booking.practitioner_id
    cyrille.reload
    assert_equal "Joe", cyrille.first_name
    assert_equal "Sullivan", cyrille.last_name
    assert_equal mail_size+1, UserEmail.all.size
    new_email = UserEmail.last
    assert_equal sav.email, new_email.to
    assert_match /#{cyrille.name}/, new_email.subject
  end

  def test_create_no_invite
    mail_size = UserEmail.all.size
    sav = practitioners(:sav)
    sav.update_attribute(:invite_on_client_book, false)
    sav.reload
    cyrille = clients(:cyrille)
    old_size = Booking.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "Joe Sullivan", :comment => "I'll be on time", :booking_type => booking_types(:sav_one_hour), 
      :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
      :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
      {:client_id => cyrille.id }
    # puts @response.body 
    assert_not_nil assigns["booking"]
    assert assigns["booking"].errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_match %r{#{assigns(:booking).practitioner.name}}, flash[:notice]
    assert_equal old_size+1, Booking.all.size
    new_booking = assigns(:booking)
    assert_equal "Joe Sullivan", new_booking.name
    assert_not_nil new_booking.starts_at
    assert_not_nil new_booking.ends_at
    assert_not_nil new_booking.booking_type
    assert_equal sav.id, new_booking.practitioner_id
    cyrille.reload
    assert_equal "Joe", cyrille.first_name
    assert_equal "Sullivan", cyrille.last_name
    assert_equal mail_size, UserEmail.all.size
  end

  def test_create_pro
    sav = practitioners(:sav)
    cyrille = clients(:cyrille)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    reminders_size = Reminder.all.size
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "undefined", :client_id => cyrille.id, :comment => "I'll be on time", :booking_type => booking_types(:sav_one_hour), 
      :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
      :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
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
    assert_equal reminders_size+1, Reminder.all.size
    assert_equal mail_size+1, UserEmail.all.size
    new_email = UserEmail.last
    assert_equal cyrille.email, new_email.to
    assert_match /#{sav.name}/, new_email.subject
  end

  def test_create_pro_longer
    megan = practitioners(:megan)
    cyrille = clients(:cyrille)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    start_date = Time.now.beginning_of_week.advance(:days=>7)
    starts = start_date.advance(:hours=>13)
    end_date = Time.now.beginning_of_week.advance(:days=>7)
    ends = end_date.advance(:hours=>14)
    post :create, {:practitioner_id => megan.permalink, :format => "json",
      :booking => {:name => "undefined", :client_id => cyrille.id, :comment => "I'll be on time", :booking_type => booking_types(:megan_two_hour), 
      :starts_at => "#{starts}",
      :ends_at => "#{ends}"}},
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
    
    #the booking should be made on the practitioner's timezone (in this case at 1pm, Megan's time)
    assert_equal start_date.in_time_zone(megan.timezone).beginning_of_day.advance(:hours=>13), new_booking.starts_at
    assert_equal end_date.in_time_zone(megan.timezone).beginning_of_day.advance(:hours => 15), new_booking.ends_at, "Sould last 2 hours, according to booking type"
    
    assert_not_nil new_booking.booking_type
    assert_equal mail_size+1, UserEmail.all.size
    new_email = UserEmail.last
    assert_equal cyrille.email, new_email.to
    assert_match /#{megan.name}/, new_email.subject
  end

  #Cyrille (7 Sep 2010: no own time option for the moment)

  # def test_create_pro_own_time
  #   sav = practitioners(:sav)
  #   cyrille = clients(:cyrille)
  #   mail_size = UserEmail.all.size
  #   old_size = Booking.all.size
  #   post :create, {:practitioner_id => sav.permalink, :format => "json",
  #     :booking => {:client_id => "", :comment => "", :booking_type => booking_types(:sav_one_hour), 
  #     :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
  #     :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
  #     {:pro_id => sav.id }
  #   # puts @response.body
  #   assert_not_nil assigns(:booking)
  #   assert assigns(:booking).errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
  #   assert_nil flash[:error]
  #   assert_not_nil flash[:notice]
  #   assert_equal old_size+1, Booking.all.size
  #   assert_equal "Own time", assigns(:booking).name
  #   assert_equal "confirmed", assigns(:booking).state, "Own time bookings are automatically confirmed"
  #   assert_equal mail_size, UserEmail.all.size, "No email should be sent as this is own time booking"
  # end
  # 
  # def test_create_pro_own_time_with_comment
  #   sav = practitioners(:sav)
  #   cyrille = clients(:cyrille)
  #   mail_size = UserEmail.all.size
  #   old_size = Booking.all.size
  #   post :create, {:practitioner_id => sav.permalink, :format => "json",
  #     :booking => {:client_id => "", :comment => "Lunch", :booking_type => booking_types(:sav_one_hour), 
  #     :starts_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
  #     :ends_at => "#{Time.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
  #     {:pro_id => sav.id }
  #   # puts @response.body
  #   assert_not_nil assigns(:booking)
  #   assert assigns(:booking).errors.blank?, "There should be no errors, but got: #{assigns['booking'].errors.full_messages.to_sentence}"
  #   assert_nil flash[:error]
  #   assert_not_nil flash[:notice]
  #   assert_equal old_size+1, Booking.all.size
  #   assert_equal "Lunch", assigns(:booking).name
  #   assert_equal "confirmed", assigns(:booking).state, "Own time bookings are automatically confirmed"
  #   assert_equal mail_size, UserEmail.all.size, "No email should be sent as this is own time booking"
  # end

  def test_create_pro_no_invite
    sav = practitioners(:sav)
    Time.zone = sav.timezone
    sav.update_attribute(:invite_on_pro_book, false)
    sav.reload
    cyrille = clients(:cyrille)
    mail_size = UserEmail.all.size
    old_size = Booking.all.size
    sav_one_hour = booking_types(:sav_one_hour)
    post :create, {:practitioner_id => sav.permalink, :format => "json",
      :booking => {:name => "undefined", :client_id => cyrille.id, :comment => "I'll be on time", :booking_type => sav_one_hour, 
      :starts_at => "#{Time.zone.now.beginning_of_week.advance(:days=>7).advance(:hours=>13)}",
      :ends_at => "#{Time.zone.now.beginning_of_week.advance(:days=>7).advance(:hours=>14)}"}},
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

  def test_index
    pro = Factory(:practitioner)
    get :index, {}, {:pro_id => pro.id }
    assert_response :success
  end

  def test_index_json
    pro = practitioners(:sav)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.beginning_of_week, :end => Time.zone.now.end_of_week}, {:client_id => clients(:cyrille).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 17, assigns(:bookings).size, "Sav should have 0 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working days, but bookings are: #{assigns(:bookings).to_sentence}"
    assert_match(/state/, @response.body)
  end

  def test_index_sav_self
    pro = practitioners(:sav)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.beginning_of_week, :end => Time.zone.now.end_of_week}, {:pro_id => practitioners(:sav).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 17, assigns(:bookings).size, "Sav should have 0 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working days, but bookings are: #{assigns(:bookings).to_json}"
  end

  def test_index_megan_next_week
    pro = practitioners(:megan)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.end_of_week, :end => Time.zone.now.end_of_week.advance(:days => 7 )}, {:client_id => clients(:cyrille).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 7, assigns(:bookings).size, "Megan should have 2 bookings and 5 non-working days, but bookings are: #{assigns(:bookings).to_json}"
    assert_match %r{Cyrille Bonnet}, @response.body, "Since Cyrille is logged in, his name should be revealed"
    assert_no_match %r{Kartini}, @response.body, "Since Cyrille is logged in, K's name should NOT be revealed"
  end

  def test_index_next_week
    pro = practitioners(:sav)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.end_of_week, :end => Time.zone.now.end_of_week.advance(:days => 7 )}, {:client_id => clients(:cyrille).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 18, assigns(:bookings).size, "Sav should have 1 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working day, but bookings are: #{assigns(:bookings).to_json}"
  end  

  def test_index_sav_own_next_week
    pro = practitioners(:sav)
    Time.zone = pro.timezone
    get :index, {:practitioner_id => pro.permalink, :format => "json", :start => Time.zone.now.end_of_week, :end => Time.zone.now.end_of_week.advance(:days => 7 )}, {:pro_id => practitioners(:sav).id }
    # puts @response.body
    assert_valid_json(@response.body)
    assert_equal 18, assigns(:bookings).size, "Sav should have 1 booking, 6 slots on 2 working days (for 12 bookings) and 5 non-working day, but bookings are: #{assigns(:bookings).to_json}"
    first_booking = assigns(:bookings).first
    assert !first_booking.read_only?, "The first booking (a booking by a client) should be editable, but it is read only"
    assert_not_equal "Booked", first_booking.name, "The client name for the first booking (a booking by a client) should be visible to the practitioner"
  end  
end
