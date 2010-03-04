role :app, "staging.colibriapp.com"
role :web, "staging.colibriapp.com"
role :db, "staging.colibriapp.com", :primary => true
set :user,          "cyrille"
set :runner,        "cyrille"
set :password,  "mavslr55"
set :deploy_to, "/var/rails/colibri_staging"
set :rails_env, :staging
set :db_user, "colibri"
set :db_name, "colibri_staging"
set :db_password, "test0user"