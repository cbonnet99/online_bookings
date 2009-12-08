class PractitionersController < ApplicationController
  
  before_filter :require_selected_practitioner, :only => [:show] 
  before_filter :login_required, :only => [:show]
  
  def new
    @practitioner = Practitioner.new
  end

  def edit_selected
    get_practitioners
  end

  def update_selected
    @practitioner = Practitioner.find(params[:practitioner_id]) unless params[:practitioner_id].nil?
    unless @practitioner.nil?
      cookies[:selected_practitioner_id] = @practitioner.id
    end
    redirect_to_target_or_default lookup_form_url(:practitioner_permalink => @practitioner.permalink)
  end
  
  def create
    @practitioner = Practitioner.new(params[:practitioner])
    if @practitioner.save
      session[:practitioner_id] = @practitioner.id
      flash[:notice] = "Thank you for signing up! You are now logged in."
      redirect_to root_url
    else
      render :action => 'new'
    end
  end
  
  def show
    
  end
end
