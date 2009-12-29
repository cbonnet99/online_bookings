class BookingsController < ApplicationController
  
  before_filter :require_selected_practitioner
  before_filter :login_required, :except => :flash 
  
  def index
    if pro_logged_in?
      @bookings = current_pro.own_bookings(params[:start].try(:to_f), params[:end].try(:to_f))
    else
      @bookings = @current_selected_pro.all_bookings(current_client, params[:start].try(:to_f), params[:end].try(:to_f))
    end
  end
  
  def show
    @booking = Booking.find(params[:id])
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
    @booking = current_client.bookings.find(params[:id])
    @booking.client_id = current_client.id
    @booking.practitioner_id = @current_selected_pro.id
    @booking.name = current_client.default_name if @booking.name.blank?
    @booking.current_client = current_client
    if @booking.nil?
      flash.now[:error] = "This appointment can not be found"
    else
      if @booking.update_attributes(params[:booking])
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
