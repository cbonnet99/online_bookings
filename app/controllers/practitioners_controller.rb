class PractitionersController < ApplicationController
  
  before_filter :require_selected_practitioner, :only => [:show] 
  before_filter :login_required, :only => [:show]

  def forgotten_password
    
  end

  def reset_ical_sharing
    if current_pro.nil?
      flash[:error] = t(:flash_error_practitioner_not_found)
    else
      current_pro.toggle_bookings_publish_code
      flash[:notice] = t(:flash_notice_practitioner_visualize_ical)
    end
    render :layout => false 
  end
  
  def new
    @practitioner = Practitioner.new
    @practitioner.working_hours = "8-12,13-18"
    @practitioner.no_cancellation_period_in_hours = 24
    @days_in_week = Practitioner::WORKING_DAYS
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
    redirect_to session[:return_to].nil? ? @practitioner : session[:return_to]
  end
  
  def clear_selected
    cookies.delete(:selected_practitioner_id)
    redirect_to root_url
  end
  
  def create
    @practitioner = Practitioner.new(params[:practitioner])
    if @practitioner.save
      session[:pro_id] = @practitioner.id
      flash[:notice] = t(:flash_notice_practitioner_thanks_signup)
      redirect_to practitioner_url(@practitioner.permalink)
    else
      @days_in_week = Practitioner::WORKING_DAYS
      render :action => 'new'
    end
  end
  
  def show
    if pro_logged_in?
      @selected_tab = "calendar"
      @clients = current_pro.clients
    end
  end
  
end
