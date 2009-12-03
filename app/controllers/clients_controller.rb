class ClientsController < ApplicationController
  def new
    @client = Client.new(:email => params[:email])
    @questions = ["What was the name of your first pet?", "What is your mother's maiden name?", "Which place did you grow up in?"]
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
      flash[:notice]="To book your first appointment, please select a question and provide an answer"
      redirect_to signup_url(:email => params[:client]["email"])
    else
      flash[:notice]="Welcome back, please enter your password"
      redirect_to login_url(:login => params[:client]["email"])
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
