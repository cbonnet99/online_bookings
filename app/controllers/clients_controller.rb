class ClientsController < ApplicationController
  before_filter :login_required, :only => [:edit, :update, :name]
  before_filter :pro_login_required, :only => [:destroy, :index]
  before_filter :locate_current_user, :only => [:homepage] 
  
  def destroy
    @client = current_pro.clients.find(params[:id])
    if @client.nil?
      flash[:error] = t(:flash_error_client_invalid_client) 
    else
      current_pro.clients.delete(@client)
      flash[:notice] = t(:flash_notice_client_client_deleted)
    end
    redirect_to practitioner_clients_url(current_pro.permalink)
  end

  def update
    @client = current_pro.nil? ? current_client : current_pro.clients.find(params[:id])
    if @client.update_attributes(params[:client])
      flash[:notice] = current_pro.nil? ? t(:flash_notice_client_info_change) : t(:flash_notice_client_client_info_change)
      redirect_to edit_client_url(@client)
    else
      flash[:error] = t(:flash_error_client_error_saving)
      @phone_prefixes = Client::PHONE_SUFFIXES
      render :action => "edit" 
    end
  end

  def homepage
    get_selected_practitioner
    # session[:return_to] = request.referer
    render :layout => "home"    
  end
  
  def index
    @selected_tab = "clients"
    @clients = current_pro.clients.find(:all, :order => "first_name, last_name" )
  end
  
  def edit
    @client = current_client
    @phone_prefixes = Client::PHONE_SUFFIXES
    session[:return_to] = request.referer
  end
  
  def request_reset_phone
    @client = Client.find_by_email(params[:email])
    if @client.nil?
     #flash[:notice] = t(:flash_notice_client_cant_find_email_in_db)
       flash[:notice] = t(:flash_notice_cant_find_email)
      redirect_to signup_url(:email => params[:email] )
    else
      @client.send_reset_phone_link
      flash[:notice] = t(:flash_notice_client_email_sent)
    end
  end

  def reset_phone
    reset_code = params[:reset_code]
    @client = Client.find_by_email(params[:email])
    if reset_code == @client.reset_code
      flash[:notice] = t(:flash_notice_client_enter_new_phone)
    else
      flash[:error] = t(:flash_error_client_problem_reset_code) + "#{APP_CONFIG[:contact_email]}"
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
      flash[:error] = t(:flash_error_client_enter_new_phone_upper)
      redirect_to edit_phone_url(:login => params["login"] )
    else
      @client = Client.find_by_email(params["login"])
      if @client.check_phone_first_4digits(params[:phone_last4digits])
        @client.phone_prefix = params[:phone_prefix]
        @client.phone_suffix = params[:phone_suffix]
        if @client.save
          session[:client_id] = @client.id
          flash[:notice] = t(:flash_notice_client_phone_changed)
          redirect_to @client
        else
          flash[:error] = t(:flash_error_client_errors_saving_phone) + "#{@client.errors.full_messages.to_sentence}"
          redirect_to edit_phone_url(:login => params["login"] )
        end
      else
        flash[:error] = t(:flash_error_client_phone_mismatch)
        redirect_to edit_phone_url(:login => params["login"] )
      end
    end
  end
    
  def new
    if pro_logged_in?
      @selected_tab = "clients"
      render :template => "clients/new_multiple"
    else
      @client = Client.new(:email => params[:email])
      get_phone_prefixes
    end
  end
  
  def lookup_form
    if client_logged_in?
      flash[:notice] = t(:flash_notice_client_welcome_back)
      redirect_to root_url
    else
      @client = Client.new(:email => params["email"])
    end
  end
  
  def lookup
    @client = Client.find_by_email(params[:client]["email"])
    if @client.nil?
      if Client.valid_email?(params[:client]["email"])
        flash[:notice]= t(:flash_notice_client_book_enter_phone)
        redirect_to signup_url(:email => params[:client]["email"])
      else
        flash[:error] = t(:flash_error_invalid_email)
        redirect_to lookup_form_url(:email =>  params[:client]["email"])
      end
    else
      flash[:notice]= t(:flash_notice_client_enter_4_digit)
      redirect_to login_phone_url(:login => params[:client]["email"])
    end
  end
    
  def login_phone
    @client = Client.find_by_email(params[:login])
    cookies[:email] = @client.email unless @client.nil?
    if @client.no_phone_number?
      flash[:warning] = t(:flash_warning_client_phone_empty)
      @client.send_reset_phone_link
      redirect_to root_url
    end
  end
  
  def login
    @client = Client.find_by_email(params[:login])
    if @client.check_phone_first_4digits(params[:phone_last4digits])
      session[:client_id] = @client.id
      flash[:notice] = t(:flash_notice_client_can_book)
      redirect_to session[:return_to] || root_url
    else
      flash[:error] = t(:flash_error_client_try_again)
      redirect_to login_phone_url(:login => params["login"] )
    end
  end
  
  def create
    if params[:emails]
      if pro_logged_in?
        begin
          current_pro.add_clients(params[:emails], params[:send_email], params[:email_text], params[:email_signoff])
        rescue BlankEmailsException
          flash[:error] = t(:flash_error_client_email_not_empty)
        rescue InvalidEmailsException => e
          flash[:error] = t(:flash_error_client_some_emails_invalid) + "#{e.message}"
        else
          flash[:notice] = t(:flash_notice_client_clients_added)
        end
        if flash[:error].blank?
          redirect_to practitioner_clients_url(current_pro.permalink)
        else
          # render :action => "new" 
          redirect_to new_practitioner_client_url(current_pro.permalink, :emails => params[:emails], :send_email => params[:send_email], :email_text => params[:email_text], :email_signoff => params[:email_signoff])
        end
      else
        flash[:error] = t(:flash_error_client_must_be_logged_in)
        redirect_to login_url
      end
    else
      @client = Client.new(params[:client])
      if @client.save
        session[:client_id] = @client.id
        flash[:notice] = t(:flash_notice_client_can_book_now)
        redirect_to session[:return_to] || @client
      else
        get_phone_prefixes
        flash[:error] = t(:flash_error_client_email_cant_register)
        render :action => 'new'
      end
    end
  end
end
