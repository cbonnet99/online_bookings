class BookingsController < ApplicationController
  
  before_filter :require_selected_practitioner
  before_filter :login_required
  
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
      flash[:error] = "This appointment can not be found"
    else
      if @booking.update_attributes(params[:booking])
        flash[:notice] = "Your appointment has been changed"
      end
    end
  end
  
  def destroy
    @booking = Booking.find(params[:id])
    @booking.destroy
    flash[:notice] = "Your appointment has been removed"
    redirect_to bookings_url
  end
end
