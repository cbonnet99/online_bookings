class PractitionersController < ApplicationController
  
  before_filter :require_selected_practitioner, :only => [:show] 
  before_filter :login_required, :only => [:update, :edit, :show, :reset_ical_sharing, :create_sample_data, :waiting_sample_data]
  before_filter :locate_current_user, :only => [:edit_selected] 

  def update
    @practitioner = @current_pro
    if @practitioner.update_attributes(params[:practitioner])
      flash[:notice] = t(:practitioner_was_saved)
      redirect_to :action => "edit" 
    else
      flash[:error] = t(:practitioner_saved_error)
      load_countries_and_days
      render :action => "edit" 
    end
  end

  def create_sample_data
    current_pro.create_sample_data!
    render :text => "Sample data created" 
  end
  
  def edit
    @practitioner = @current_pro
    load_countries_and_days
  end

  def reset_ical_sharing
    if current_pro.nil?
      flash.now[:error] = I18n.t(:flash_error_practitioner_not_found)
    else
      current_pro.toggle_bookings_publish_code
      flash.now[:notice] = I18n.t(:flash_notice_practitioner_visualize_ical)
    end
    render :layout => false 
  end
  
  def new
    @practitioner = Practitioner.new
    @practitioner.sample_data = true
    @practitioner.lunch_break = true
    @practitioner.start_time1 = 8
    @practitioner.end_time1 = 12
    @practitioner.start_time2 = 13
    @practitioner.end_time2 = 18
    @practitioner.own_time_label = "Own time"
    @practitioner.no_cancellation_period_in_hours = 24
    @practitioner.country = default_country
    load_countries_and_days
  end

  def edit_selected
    get_practitioners(@current_country_code)
    # session[:return_to] = request.referer
    session[:return_to] = nil
  end

  def update_selected
    @practitioner = Practitioner.find(params[:practitioner_id]) unless params[:practitioner_id].nil?
    unless @practitioner.nil?
      cookies[:selected_practitioner_id] = @practitioner.id
      Time.zone = @practitioner.timezone
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
      Time.zone = @practitioner.timezone
      if @practitioner.create_sample_data?
        redirect_to waiting_sample_data_practitioner_url(@practitioner.permalink)
      else
        if params[:paying].nil?
          flash[:notice] = I18n.t(:flash_notice_practitioner_thanks_signup)
          redirect_to practitioner_url(@practitioner.permalink)
        else
          flash[:notice] = I18n.t(:flash_notice_practitioner_thanks_payment)
          redirect_to new_payment_url
        end
      end
    else
      load_countries_and_days
      get_phone_prefixes
      render :action => 'new'
    end
  end
  
  def show
    if pro_logged_in?
      @selected_tab = "calendar"
      @clients = current_pro.clients
    end
  end

private
  def load_countries_and_days
    @supported_countries = Country.available_countries
    @days_in_week = Practitioner::WORKING_DAYS    
  end
  
end
