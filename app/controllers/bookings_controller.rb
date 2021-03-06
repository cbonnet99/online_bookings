class BookingsController < ApplicationController
  
  before_filter :pro_login_required, :except => [:flash, :index_cal, :client_confirm, :client_cancel]
  before_filter :get_booking, :only => [:edit, :show, :cancel_text, :pro_cancel, :pro_confirm] 
  
  def cancel_text
    if @booking.nil?
      render :text  => ""
    else
      render :text => @booking.cancellation_text.gsub(%r{<br/>}, "\n")
    end
  end

  def client_cancel
    @booking = Booking.find_by_confirmation_code_and_id(params[:confirmation_code], params[:id])
    if @booking.nil?
      logger.error("Invalid attempt to cancel a booking with ID: #{params[:id]} and confirmation_code: #{params[:confirmation_code]}")
      flash[:error] = I18n.t(:flash_error_booking_cannot_be_cancelled)
    else
      @booking.client_cancel!
      flash[:notice] = I18n.t(:flash_notice_booking_appointment_cancelled , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" ,:booking_time => @booking.start_date_and_time_str)
    end    
  end

  def pro_cancel
    if @booking.nil?
      logger.error("Error in pro_cancel: booking ID: #{params[:id]} doesn't exist for pro ID: #{current_pro.id}")
      flash[:error] = I18n.t(:flash_error_booking_cannot_be_cancelled)
    else
      @booking.pro_cancel!
      if params[:send_email]
        @cancellation_text = params[:cancellation_text].blank? ? @booking.cancellation_text : params[:cancellation_text].gsub(/\n/, "<br/>")
        UserMailer.deliver_cancellation_notice(@booking,  @cancellation_text)
      end
      flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_cancelled , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" ,:booking_time => @booking.start_date_and_time_str)
    end
    render :action => "flash", :format => "json"
  end
  

  
  def client_confirm
    @booking = Booking.find_by_confirmation_code_and_id(params[:confirmation_code], params[:id])
    if @booking.nil?
      logger.error("Invalid attempt to confirm an with ID: #{params[:id]} and confirmation_code: #{params[:confirmation_code]}")
      flash.now[:error] = I18n.t(:flash_error_booking_invalid_appointment)
    else
      if @booking.confirmed?
        flash.now[:notice] = I18n.t(:flash_notice_booking_already_confirmed)
      else
        @booking.confirm!
        flash.now[:notice] = I18n.t(:flash_notice_booking_confirmed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_time => @booking.start_date_and_time_str)
      end
    end
  end
  
  def pro_confirm
    if @booking.nil?
      logger.error("Invalid attempt to confirm an with ID: #{params[:id]} for pro: #{current_pro.id}")
      flash.now[:error] = I18n.t(:flash_error_booking_invalid_appointment)
    else
      @booking.confirm!
      flash.now[:notice] = I18n.t(:flash_notice_booking_confirmed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_time => @booking.start_date_and_time_str)
    end
    render :action => "flash", :format => "json"
  end
  
  def index
    respond_to do |format|
      format.html do
        starts_at = params[:start].nil? ? Time.zone.now.beginning_of_day : params[:start].try(:to_f)
        ends_at = params[:end].nil? ? Time.zone.now.end_of_day : params[:end].try(:to_f)
        @bookings = current_pro.raw_own_bookings(starts_at, ends_at)
      end
      format.json do
        if pro_logged_in?
          @bookings = current_pro.own_bookings(params[:start].try(:to_f), params[:end].try(:to_f))
        else
          @bookings = @current_selected_pro.all_bookings(current_client, params[:start].try(:to_f), params[:end].try(:to_f))
        end
      end
    end
  end

  def index_cal
    @practitioner = Practitioner.find_by_bookings_publish_code(params["pub_code"])
    if @practitioner.nil?
      flash.now[:error] = I18n.t(:flash_error_booking_couldnot_find_practitioner)
      redirect_to root_url
    else
      @bookings = @practitioner.raw_own_bookings(Time.zone.now.advance(:month => -1).beginning_of_month, Time.zone.now.advance(:months => 1).end_of_month)
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
    if client_logged_in?
      client = current_client  
      pro = @current_selected_pro
    else
      pro = current_pro
    end
    unless @booking.client_id.blank?
      client = current_pro.clients.find(@booking.client_id)
      @booking.name = client.try(:default_name)
    end
    if @booking.client_id.blank? && !@booking.client_email.blank?
      client = current_pro.clients.find_by_email(@booking.client_email)
    end
    @booking.set_defaults(current_client, current_pro, client, pro)
    if @booking.save
      @prep = @booking.prep
      flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_booked , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_time => @booking.start_date_and_time_str)
    else
      flash.now[:error] = I18n.t(:booking_not_saved, :error => @booking.errors.full_messages.to_sentence)
    end
    render :action => "flash", :format => "json"
  end
  
  def update
    @booking, hash_booking = Booking.prepare_update(current_pro, current_client, @current_selected_pro, params[:booking], params[:id])
    if @booking.nil?
      flash.now[:error] = I18n.t(:flash_error_booking_appointment_not_found)
    else
      if @booking.in_grace_period?
        if @booking.update_attributes(JsonUtils.scrub_undefined(JsonUtils.remove_timezone(hash_booking)))
          @prep = @booking.prep
          flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_changed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_time => @booking.start_date_and_time_str)
        else
          flash.now[:error] = I18n.t(:error_while_saving_booking)
        end
      else
        flash.now[:error] = I18n.t(:error_saving_booking_outside_of_grace_period)
      end
    end
    render :action => "flash", :format => "json"
  end
  
  def destroy
    @booking = Booking.prepare_delete(current_pro, current_client, params[:id])
    str = "with #{@booking.partner_name(current_client, current_pro)} #{@booking.start_date_and_time_str}"
    if @booking.nil?
      flash.now[:error] = I18n.t(:flash_error_booking_appointment_not_found)
    else
      @booking.check_in_grace_period
      @booking_id = @booking.id
      @prep_id = "#{Booking::PREP_LABEL}#{@booking_id}" if @booking.prep_time_mins > 0
      @booking.destroy
      flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_removed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_time => @booking.start_date_and_time_str)
    end
    render :action => "flash", :format => "json"
  end
  
private
  def get_booking
    @booking = current_pro.bookings.find(params[:id])
  end
end
