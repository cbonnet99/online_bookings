class ClientsController < ApplicationController
  before_filter :login_required, :only => [:edit, :update]

  def index
    get_practitioners
    session[:return_to] = request.referer
  end
  
  def edit
    @client = current_client
    @phone_prefixes = Client::PHONE_SUFFIXES
    session[:return_to] = request.referer
  end

  def update
    
  end
  
  def request_reset_phone
    @client = Client.find_by_email(params[:email])
    if @client.nil?
      flash[:notice] = "We can not find your email address in our records, please register with us"
      redirect_to signup_url(:email => params[:email] )
    else
      @client.send_reset_phone_link
      flash[:notice] = "We've sent you an email"
    end
  end

  def reset_phone
    reset_code = params[:reset_code]
    @client = Client.find_by_email(params[:email])
    if reset_code == @client.reset_code
      flash[:notice] = "Please enter a new phone number"
    else
      flash[:error] = "Sorry, there is a problem with your reset code. Please contact us at #{APP_CONFIG[:contact_email]}"
      redirect_to root_url
    end
  end

  def edit_phone
    if logged_in?
      redirect_to edit_client_url(current_client)
    else
      @client = Client.find_by_email(params["login"])
      @phone_prefixes = Client::PHONE_SUFFIXES
    end
  end

  def update_phone
    if params[:phone_suffix].blank?
      flash[:error] = "Please enter a NEW phone number"
      redirect_to edit_phone_url(:login => params["login"] )
    else
      @client = Client.find_by_email(params["login"])
      if @client.check_phone_first_4digits(params[:phone_last4digits])
        @client.phone_prefix = params[:phone_prefix]
        @client.phone_suffix = params[:phone_suffix]
        if @client.save
          session[:client_id] = @client.id
          flash[:notice] = "Your phone number has been changed"
          redirect_to @client
        else
          flash[:error] = "There were some errors while saving your phone number: #{@client.errors.full_messages.to_sentence}"
          redirect_to edit_phone_url(:login => params["login"] )
        end
      else
        flash[:error] = "Sorry, the numbers do not match. Please try again."
        redirect_to edit_phone_url(:login => params["login"] )
      end
    end
  end
    
  def new
    @client = Client.new(:email => params[:email])
    @phone_prefixes = Client::PHONE_SUFFIXES
  end
  
  def lookup_form
    if logged_in?
      flash[:notice] = "Welcome back!"
      redirect_to root_url
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
    if @client.no_phone_number?
      flash[:warning] = "Our records show that your phone number is empty: we have sent you an email with a link to reset your phone number."
      @client.send_reset_phone_link
      redirect_to root_url
    end
  end
  
  def login
    @client = Client.find_by_email(params["login"])
    if @client.check_phone_first_4digits(params[:phone_last4digits])
      session[:client_id] = @client.id
      flash[:notice] = "You can now book your appointment"
      redirect_to session[:return_to] || root_url
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
