class PractitionersController < ApplicationController
  
  before_filter :require_selected_practitioner, :only => [:show] 
  before_filter :login_required, :only => [:show]

  def reset_ical_sharing
    if current_pro.nil?
      flash[:error] = "Could not find this practitioner"
    else
      current_pro.toggle_bookings_publish_code
      flash[:notice] = "You can now visualize your calendar in iCal"
    end
    render :layout => false 
  end
  
  def new
    @practitioner = Practitioner.new
    @practitioner.working_hours = "8-12,13-18"
    @days_in_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  end

  def edit_selected
    get_practitioners
    # session[:return_to] = request.referer
    session[:return_to] = nil
  end

  def update_selected
    @practitioner = Practitioner.find(params[:practitioner_id]) unless params[:practitioner_id].nil?
    unless @practitioner.nil?
      cookies[:selected_practitioner_id] = @practitioner.id
    end
    if session[:return_to].nil?
      redirect_to @practitioner
    else
      redirect_to session[:return_to]
    end
  end
  
  def create
    @practitioner = Practitioner.new(params[:practitioner])
    if @practitioner.save
      session[:practitioner_id] = @practitioner.id
      flash[:notice] = "Thank you for signing up! You are now logged in."
      redirect_to practitioner_url(@practitioner.id)
    else
      @days_in_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      render :action => 'new'
    end
  end
  
  def show
    if pro_logged_in?
      @clients = current_pro.clients
    end
  end
  
end
