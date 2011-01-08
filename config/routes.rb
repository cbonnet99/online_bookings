ActionController::Routing::Routes.draw do |map|

  #BOOKINGS
  map.calendar_bookings '/practitioners/:practitioner_id/bookings/:pub_code', :controller => 'bookings', :action => 'index_cal', :format  => "ics"

  map.resources :practitioners, :member => {:reset_ical_sharing  => [:get, :post], :waiting_sample_data => :get, :create_sample_data  => :post}
  map.resources :practitioners do |p|
    p.resources :bookings
  end

  map.resources :practitioners do |p|
    p.resources :clients
  end


  #FLASH
  map.flash 'flash', :controller => 'bookings', :action => 'flash'

  #COUNTRIES
  map.country_mobile_phone_prefixes '/countries/mobile_phone_prefixes/:id', :controller => 'countries', :action => 'mobile_phone_prefixes'
  
  #PRACTITIONER
  map.edit_selected_practitioner 'edit_selected_practitioner', :controller => 'practitioners', :action => 'edit_selected'
  map.update_selected_practitioner 'update_selected_practitioner', :controller => 'practitioners', :action => 'update_selected'
  map.clear_selected_practitioner 'clear_selected_practitioner', :controller => 'practitioners', :action => 'clear_selected'
  map.forgotten_password 'forgotten_password', :controller => 'practitioners', :action => 'forgotten_password'
    
  #CLIENT
  map.country_select 'country_select.:format', :controller => 'clients', :action => 'country_select'
  map.homepage 'homepage', :controller => 'clients', :action => 'homepage'
  map.explanation 'explanation', :controller => 'clients', :action => 'explanation'
  map.edit_phone 'edit_phone', :controller => 'clients', :action => 'edit_phone'
  map.update_phone 'update_phone', :controller => 'clients', :action => 'update_phone'
  map.reset_phone 'reset_phone', :controller => 'clients', :action => 'reset_phone'
  map.request_reset_phone 'request_reset_phone', :controller => 'clients', :action => 'request_reset_phone'
  map.update_reset_phone 'request_reset_phone', :controller => 'clients', :action => 'update_reset_phone'
  map.client_login 'client_login', :controller => 'clients', :action => 'login'
  map.client_name 'client_name', :controller => 'clients', :action => 'name'
  map.login_phone 'login_phone', :controller => 'clients', :action => 'login_phone'
  map.lookup 'lookup', :controller => 'clients', :action => 'lookup'
  map.lookup_form 'lookup_form', :controller => 'clients', :action => 'lookup_form'
  map.signup 'signup', :controller => 'clients', :action => 'new'
  map.logout 'logout', :controller => 'sessions', :action => 'destroy'
  map.login 'login', :controller => 'sessions', :action => 'new'
  map.resources :sessions
  map.resources :payments

  map.resources :clients do |c|
    c.resources :bookings
  end

  map.resources :bookings, :member => {:client_confirm => [:post, :get], :client_cancel => [:post, :get], :pro_confirm => [:post, :get], 
    :pro_cancel => [:post, :get], :cancel_text  => :get } 

  map.resources :clients, :member => {:calendar => :get }

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.root :controller => 'clients', :action => 'homepage'
end
