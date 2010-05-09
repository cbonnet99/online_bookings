class BookingsController < ApplicationController
  
  before_filter :require_selected_practitioner, :except => [:confirm, :cancel] 
  before_filter :login_required, :except => [:flash, :index_cal, :confirm, :cancel]

  def cancel
    @booking = Booking.find_by_confirmation_code_and_id(params[:confirmation_code], params[:id])
    if @booking.nil?
      logger.error("Invalid attempt to cancel an with ID: #{params[:id]} and confirmation_code: #{params[:confirmation_code]}")
      flash[:error] = I18n.t(:flash_error_booking_invalid_appointment)
    else
      @booking.cancel!
      flash[:notice] = I18n.t(:flash_notice_booking_appointment_cancelled , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date => l(@booking.start_date,:format => :custo_date),:booking_time => l(@booking.start_time, :format => :timeampm))
    end    
  end
  
  def confirm
    @booking = Booking.find_by_confirmation_code_and_id(params[:confirmation_code], params[:id])
    if @booking.nil?
      logger.error("Invalid attempt to confirm an with ID: #{params[:id]} and confirmation_code: #{params[:confirmation_code]}")
      flash[:error] = I18n.t(:flash_error_booking_invalid_appointment)
    else
      @booking.confirm!
      flash[:notice] = I18n.t(:flash_notice_booking_confirmed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date => l(@booking.start_date,:format => :custo_date),:booking_time => l(@booking.start_time, :format => :timeampm))
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
      flash[:error] = I18n.t(:flash_error_booking_couldnot_find_practitioner)
      render :action => "flash"
    else
      @bookings = @practitioner.own_bookings(Time.zone.now.advance(:month => -1).beginning_of_month, Time.zone.now.advance(:months => 1).end_of_month)
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
    @booking = Booking.new(JsonUtils.scrub_undefined(JsonUtils.remove_timezone(params[:booking])))
    if @booking.client_id.nil?
      client = current_client
      pro = @current_selected_pro
    else
      client = current_pro.clients.find(@booking.client_id)
      pro = current_pro
      @booking.name = @client.try(:default_name)
    end
    @booking.set_defaults(current_client, current_pro, client, pro)
    if @booking.save
      @prep = @booking.prep
      flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_booked , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date => l(@booking.start_date,:format => :custo_date),:booking_time => l(@booking.start_time, :format => :timeampm))
      #flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_booked , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date =>  l(Time.now, :format => :booking))
       #flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_booked , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date =>  Time.now)          
    end
  end
  
  def edit
    @booking = Booking.find(params[:id])
  end
  
  def update
    @booking, hash_booking = Booking.prepare_update(current_pro, current_client, @current_selected_pro, params[:booking], params[:id])
    if @booking.nil?
      flash.now[:error] = I18n.t(:flash_error_booking_appointment_not_found)
    else
      if @booking.update_attributes(hash_booking)
        @prep = @booking.prep
        flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_changed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date => l(@booking.start_date,:format => :custo_date),:booking_time => l(@booking.start_time, :format => :timeampm))
      end
    end
  end
  
  def destroy
    @booking = Booking.prepare_delete(current_pro, current_client, params[:id])
    str = "with #{@booking.partner_name(current_client, current_pro)} #{@booking.start_date_and_time_str}"
    if @booking.nil?
      flash.now[:error] = I18n.t(:flash_error_booking_appointment_not_found)
    else
      @booking_id = @booking.id
      @prep_id = "#{Booking::PREP_LABEL}#{@booking_id}" if @booking.prep_time_mins > 0
      @booking.destroy
      flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_removed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date => l(@booking.start_date,:format => :custo_date),:booking_time => l(@booking.start_time, :format => :timeampm))
    end
  end
end
