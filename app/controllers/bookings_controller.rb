class BookingsController < ApplicationController
  
  before_filter :require_selected_practitioner
  before_filter :login_required, :except => :flash 
  
  def index
    @bookings = @current_selected_pro.all_bookings(current_client, params[:start].try(:to_f), params[:end].try(:to_f))
  end
  
  def show
    @booking = Booking.find(params[:id])
  end
  
  def new
    @booking = Booking.new
  end
  
  def create
    @booking = Booking.new(params[:booking])
    @booking.client_id = current_client.id
    @booking.practitioner_id = @current_selected_pro.id
    @booking.name = current_client.default_name if @booking.name.blank?
    @booking.current_client = current_client
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
