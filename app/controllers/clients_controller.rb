class ClientsController < ApplicationController
  before_filter :login_required, :only => [:edit, :update, :name]
  before_filter :pro_login_required, :only => [:destroy]

  def destroy
    @client = current_pro.clients.find(params[:id])
    if @client.nil?
      flash[:error] = "Invalid client"
    else
      current_pro.clients.delete(@client)
      flash[:notice] = "Client deleted"
    end
    redirect_to practitioner_clients_url(current_pro.permalink, :tab => "clients")
  end

  def update
    @client = current_pro.nil? ? current_client : current_pro.clients.find(params[:id])
    if @client.update_attributes(params[:client])
      flash[:notice] = current_pro.nil? ? "Your information was changed" : "Client information was changed"
      redirect_to edit_client_url(@client)
    else
      flash[:error] = "Error while saving information"
      @phone_prefixes = Client::PHONE_SUFFIXES
      render :action => "edit" 
    end
  end

  def index
    if pro_logged_in?
      @clients = current_pro.clients.find(:all, :order => "first_name, last_name" )
      render :template => "clients/index_pro" 
    else
      get_selected_practitioner
      get_practitioners
      # session[:return_to] = request.referer
    end
  end
  
  def edit
    @client = current_client
    @phone_prefixes = Client::PHONE_SUFFIXES
    session[:return_to] = request.referer
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
    if client_logged_in?
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
    if pro_logged_in?
      render :template => "clients/new_multiple"
    else
      @client = Client.new(:email => params[:email])
      get_phone_prefixes
    end
  end
  
  def lookup_form
    if client_logged_in?
      flash[:notice] = "Welcome back!"
      redirect_to root_url
    else
      @client = Client.new(:email => params["email"])
    end
  end
  
  def lookup
    @client = Client.find_by_email(params[:client]["email"])
    if @client.nil?
      if Client.valid_email?(params[:client]["email"])
        flash[:notice]="To book your first appointment, please enter your phone number"
        redirect_to signup_url(:email => params[:client]["email"])
      else
        flash[:error] = "The email address is not valid: maybe you are missing a dot(.) or the @ sign?"
        redirect_to lookup_form_url(:email =>  params[:client]["email"])
      end
    else
      flash[:notice]="Welcome back, please enter the last 4 digits of your phone number"
      redirect_to login_phone_url(:login => params[:client]["email"])
    end
  end
    
  def login_phone
    @client = Client.find_by_email(params[:login])
    cookies[:email] = @client.email unless @client.nil?
    if @client.no_phone_number?
      flash[:warning] = "Our records show that your phone number is empty: we have sent you an email with a link to reset your phone number."
      @client.send_reset_phone_link
      redirect_to root_url
    end
  end
  
  def login
    @client = Client.find_by_email(params[:login])
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
    if params[:emails]
      if pro_logged_in?
        begin
          current_pro.add_clients(params[:emails], params[:send_email], params[:email_text], params[:email_signoff])
        rescue BlankEmailsException
          flash[:error] = "Email addresses can not be empty"
        rescue InvalidEmailsException => e
          flash[:error] = "Some email addresses are invalid: #{e.message}"
        else
          flash[:notice] = "Clients were added"
        end
        if flash[:error].blank?
          redirect_to practitioner_clients_url(current_pro.permalink, :tab => "clients")
        else
          # render :action => "new" 
          redirect_to new_practitioner_client_url(current_pro.permalink, :emails => params[:emails], :send_email => params[:send_email], :email_text => params[:email_text], :email_signoff => params[:email_signoff], :tab => "clients")
        end
      else
        flash[:error] = "You must be logged in"
        redirect_to login_url
      end
    else
      @client = Client.new(params[:client])
      if @client.save
        session[:client_id] = @client.id
        flash[:notice] = "You can now book your appointment"
        redirect_to session[:return_to] || @client
      else
        get_phone_prefixes
        flash[:error] = "This email address can not be registered"
        render :action => 'new'
      end
    end
  end
end
