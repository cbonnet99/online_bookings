class ClientsController < ApplicationController
  def new
    @client = Client.new(:email => params[:email])
    @phone_prefixes = Client::PHONE_SUFFIXES
  end
  
  def lookup_form
    if logged_in?
      flash[:notice] = "Welcome back!"
      redirect_to current_client
    else
      @client = Client.new
    end
  end
  
  def lookup
    @client = Client.find_by_email(params[:client]["email"])
    if @client.nil?
      flash[:notice]="To book your first appointment, please enter your phone number"
      redirect_to signup_url(:email => params[:client]["email"])
    else
      flash[:notice]="Welcome back, please enter the last 4 digits of your phone number"
      redirect_to login_phone_url(:login => params[:client]["email"])
    end
  end
    
  def login_phone
    @client = Client.find_by_email(params[:login])
  end
  
  def login
    @client = Client.find_by_email(params["login"])
    if @client.check_phone_first_4digits(params[:phone_last4digits])
      session[:client_id] = @client.id
      flash[:notice] = "You can now book your appointment"
      redirect_to @client
    else
      flash[:error] = "Sorry, the numbers do not match. Please try again."
      redirect_to login_phone_url(:login => params["login"] )
    end
  end
  
  def create
    @client = Client.new(params[:client])
    if @client.save
      session[:client_id] = @client.id
      flash[:notice] = "You can now book your appointment"
      redirect_to @client
    else
      @questions = ["What was the name of your first pet?", "What is your mother's maiden name?", "Which place did you grow up in?"]
      render :action => 'new'
    end
  end
end
