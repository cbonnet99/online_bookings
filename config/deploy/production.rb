role :app, "www.colibriapp.com"
role :web, "www.colibriapp.com"
role :db, "www.colibriapp.com", :primary => true
set :user,          "cyrille"
set :runner,        "cyrille"
set :password,  "mavslr55"
set :deploy_to, "/var/rails/colibri_production"
set :rails_env, :production
set :db_user, "colibri"
set :db_name, "colibri_production"
set :db_password, "test0user"