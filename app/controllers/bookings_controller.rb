class BookingsController < ApplicationController
  
  before_filter :get_selected_practitioner
  
  def index
    @bookings = Booking.find_all_by_practitioner_id(@current_selected_pro)
  end
  
  def show
    @booking = Booking.find(params[:id])
  end
  
  def new
    @booking = Booking.new
  end
  
  def create
    @booking = Booking.new(params[:booking])
    if @booking.save
      flash[:notice] = "Successfully created booking."
      redirect_to @booking
    else
      render :action => 'new'
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
