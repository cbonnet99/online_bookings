class PractitionersController < ApplicationController
  
  before_filter :require_selected_practitioner, :only => [:show] 
  before_filter :login_required, :only => [:show]
  
  def new
    @practitioner = Practitioner.new
  end

  def edit_selected
    get_practitioners
    session[:return_to] = request.referer
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
      redirect_to root_url
    else
      render :action => 'new'
    end
  end
  
end
