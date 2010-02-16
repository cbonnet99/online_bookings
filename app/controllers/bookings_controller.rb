class BookingsController < ApplicationController
  
  before_filter :require_selected_practitioner, :except => [:confirm, :cancel] 
  before_filter :login_required, :except => [:flash, :index_cal, :confirm, :cancel]

  def cancel
    @booking = Booking.find_by_confirmation_code_and_id(params[:confirmation_code], params[:id])
    if @booking.nil?
      logger.error("Invalid attempt to cancel an with ID: #{params[:id]} and confirmation_code: #{params[:confirmation_code]}")
      flash[:error] = "This appointment is invalid"
    else
      @booking.cancel!
      flash[:notice] = "Your appointment was cancelled"
    end    
  end
  
  def confirm
    @booking = Booking.find_by_confirmation_code_and_id(params[:confirmation_code], params[:id])
    if @booking.nil?
      logger.error("Invalid attempt to confirm an with ID: #{params[:id]} and confirmation_code: #{params[:confirmation_code]}")
      flash[:error] = "This appointment is invalid"
    else
      @booking.confirm!
      flash[:notice] = "Your appointment was confirmed"
    end
  end
  
  def index
    if pro_logged_in?
      @bookings = current_pro.own_bookings(params[:start].try(:to_f), params[:end].try(:to_f))
    else
      @bookings = @current_selected_pro.all_bookings(current_client, params[:start].try(:to_f), params[:end].try(:to_f))
    end
  end

  def index_cal
    @practitioner = Practitioner.find_by_bookings_publish_code(params["pub_code"])
    if @practitioner.nil?
      flash[:error] = "Could not find this practitioner"
      render :action => "flash"
    else
      @bookings = @practitioner.own_bookings(Time.now.advance(:month => -1).beginning_of_month, Time.now.advance(:months => 1).end_of_month)
      calendar = Icalendar::Calendar.new
      @bookings.each do |b|
        calendar.add_event(b.to_ics)
      end
      calendar.publish
      headers['Content-Type'] = "text/calendar; charset=UTF-8"
      render :text => calendar.to_ical
    end 
  end
    
  def new
    @booking = Booking.new
  end
  
  def create
    @booking = Booking.new(JsonUtils.scrub_undefined(params[:booking]))
    if @booking.client_id.nil?
      client = current_client
      pro = @current_selected_pro
    else
      client = current_pro.clients.find(@booking.client_id)
      pro = current_pro
      @booking.name = @client.try(:default_name)
    end
    @booking.current_client = client
    @booking.current_pro = pro
    @booking.name = client.try(:default_name) if @booking.name.blank?
    @booking.client_id = client.try(:id)
    @booking.practitioner_id = pro.try(:id)
    if @booking.save
      flash.now[:notice] = "Your appointment has been booked"
    end
  end
  
  def edit
    @booking = Booking.find(params[:id])
  end
  
  def update
    hash_booking = params[:booking]
    if current_pro.nil?
      @booking = current_client.bookings.find(params[:id])
      @booking, hash_booking = current_client.update_booking(@booking, hash_booking, current_client, @current_selected_pro)
    else
      @booking = current_pro.bookings.find(params[:id])
      @booking, hash_booking = current_pro.update_booking(@booking, hash_booking, current_pro)      
    end
    if @booking.nil?
      flash.now[:error] = "This appointment can not be found"
    else
      if @booking.update_attributes(hash_booking)
        flash.now[:notice] = "Your appointment has been changed"
      end
    end
  end
  
  def destroy
    @booking = current_client.bookings.find(params[:id])
    if @booking.nil?
      flash.now[:error] = "This appointment could not be found"
    else
      @booking.destroy
      flash.now[:notice] = "Your appointment has been removed"
    end
  end
end
