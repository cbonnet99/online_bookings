class BookingsController < ApplicationController
  
  before_filter :get_selected_practitioner
  
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
    if current_client.nil?
      flash[:error] = "Not authenticated as a client"
      return false
    end
    if @current_selected_pro.nil?
      flash[:error] = "No selected practitioner"
      return false
    end
    @booking = Booking.new(params[:booking])
    @booking.client_id = current_client.id
    @booking.practitioner_id = @current_selected_pro.id
    @booking.name = current_client.default_name if @booking.name.blank?
    @booking.current_client = current_client
    if @booking.save
      flash.now[:notice] = "Your appointment is booked"
    end
  end
  
  def edit
    @booking = Booking.find(params[:id])
  end
  
  def update
    @booking = Booking.find(params[:id])
    if @booking.update_attributes(params[:booking])
      flash[:notice] = "Successfully updated booking."
      redirect_to @booking
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @booking = Booking.find(params[:id])
    @booking.destroy
    flash[:notice] = "Successfully destroyed booking."
    redirect_to bookings_url
  end
end
