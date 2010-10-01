class BookingsController < ApplicationController
  
  before_filter :require_selected_practitioner, :except => [:confirm, :cancel] 
  before_filter :login_required, :except => [:flash, :index_cal, :confirm, :cancel]

  def cancel
    if pro_logged_in?
      @booking = current_pro.bookings.find(params[:id])
    else
      @booking = Booking.find_by_confirmation_code_and_id(params[:confirmation_code], params[:id])
    end
    if @booking.nil?
      logger.error("Invalid attempt to cancel an with ID: #{params[:id]} and confirmation_code: #{params[:confirmation_code]}")
      flash[:error] = I18n.t(:flash_error_booking_cannot_be_cancelled)
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
    respond_to do |format|
      format.html do
        starts_at = params[:start].nil? ? Time.now.beginning_of_day : params[:start].try(:to_f)
        ends_at = params[:end].nil? ? Time.now.end_of_day : params[:end].try(:to_f)
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
    if client_logged_in?
      client = current_client  
      pro = @current_selected_pro
    else
      pro = current_pro
    end
    unless @booking.client_id.nil?
      client = current_pro.clients.find(@booking.client_id)
      @booking.name = client.try(:default_name)
    end
    @booking.set_defaults(current_client, current_pro, client, pro)
    if @booking.save
      @prep = @booking.prep
      flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_booked , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date => l(@booking.start_date,:format => :custo_date),:booking_time => l(@booking.start_time, :format => :timeampm))
    else
      flash[:error] = I18n.t(:booking_not_saved, :error => @booking.errors.full_messages.to_sentence)
    end
    render :view => "flash", :format => "json"
  end
  
  def edit
    @booking = Booking.find(params[:id])
  end
  
  def update
    @booking, hash_booking = Booking.prepare_update(current_pro, current_client, @current_selected_pro, params[:booking], params[:id])
    if @booking.nil?
      flash.now[:error] = I18n.t(:flash_error_booking_appointment_not_found)
    else
      if @booking.in_grace_period?
        if @booking.update_attributes(hash_booking)
          @prep = @booking.prep
          flash.now[:notice] = I18n.t(:flash_notice_booking_appointment_changed , :booking_partner => "#{@booking.partner_name(current_client, current_pro)}" , :booking_date => l(@booking.start_date,:format => :custo_date),:booking_time => l(@booking.start_time, :format => :timeampm))
        else
          flash[:error] = I18n.t(:error_while_saving_booking)
        end
      else
        flash[:error] = I18n.t(:error_saving_booking_outside_of_grace_period)
      end
    end
    render :view => "flash", :format => "json"
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
