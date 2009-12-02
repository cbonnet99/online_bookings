class ClientsController < ApplicationController
  def calendar
  end

  def index
    @clients = Client.all
  end
  
  def show
    @client = Client.find(params[:id])
  end
  
  def new
    @client = Client.new
    @questions = ["What was the name of your first pet?", "What is your mother's maiden name?", "Which place did you grow up in?"]
  end
  
  def create
    @client = Client.new(params[:client])
    if @client.save
      flash[:notice] = "Welcome to #{APP_CONFIG[:site_name]}"
      redirect_to @client
    else
      render :action => 'new'
    end
  end
  
  def edit
    @client = Client.find(params[:id])
  end
  
  def update
    @client = Client.find(params[:id])
    if @client.update_attributes(params[:client])
      flash[:notice] = "Successfully updated client."
      redirect_to @client
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @client = Client.find(params[:id])
    @client.destroy
    flash[:notice] = "Successfully destroyed client."
    redirect_to clients_url
  end
end
