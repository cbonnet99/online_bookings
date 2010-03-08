# This module is included in your application controller which makes
# several methods available to all controllers and views. Here's a
# common example you might add to your application layout file.
# 
#   <% if logged_in? %>
#     Welcome <%=h current_client.username %>! Not you?
#     <%= link_to "Log out", logout_path %>
#   <% else %>
#     <%= link_to "Sign up", signup_path %> or
#     <%= link_to "log in", login_path %>.
#   <% end %>
# 
# You can also restrict unregistered users from accessing a controller using
# a before filter. For example.
# 
#   before_filter :login_required, :except => [:index, :show]
module Authentication
  def self.included(controller)
    controller.send :helper_method, :current_client, :client_logged_in?, :redirect_to_target_or_default
    controller.send :helper_method, :current_pro, :pro_logged_in?, :redirect_to_target_or_default
    controller.filter_parameter_logging :password
  end
  
  def current_client
    @current_client ||= Client.find(session[:client_id]) if session[:client_id]
  end
  
  def current_pro
    @current_pro ||= Practitioner.find(session[:pro_id]) if session[:pro_id]
  end
  
  def client_logged_in?
    current_client
  end
  
  def pro_logged_in?
    current_pro
  end
  
  def login_required
    unless client_logged_in? || pro_logged_in?
      respond_to do |format|
        format.html do
          store_target_location
          if params[:email]
            flash[:error] = "Please enter your phone number"
            redirect_to login_phone_url(:login => params[:email] )
          else
            flash[:error] = "Please enter your email address"
            redirect_to lookup_form_url
          end
        end
        format.json do
          flash[:error] = "Not authenticated as a client"
          redirect_to flash_url
        end
      end
    end
  end
  
  def pro_login_required
    unless pro_logged_in?
      flash[:error] = "You must be logged in to see this page"
      store_target_location
      redirect_to login_url
    end
  end
  
  def redirect_to_target_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
  private
  
  def store_target_location
    session[:return_to] = request.request_uri
  end
end
