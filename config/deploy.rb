set :application, "online_bookings"

set :scm_username,  "cbonnet99@gmail.com"
#set :scm_password,  lambda { CLI.password_prompt "SVN Password (user: #{scm_username}): "}
set :deploy_via, :remote_cache
# set :deploy_via,  :copy
set :scm, :git
#set :repository, "git://github.com/cbonnet99/cbba.git"
set :repository, "git@github.com:cbonnet99/online_bookings.git"
set :branch, "master"
ssh_options[:forward_agent] = true

role :app, "75.101.132.186"
role :web, "75.101.132.186"
role :db, "75.101.132.186", :primary => true
set :user,          "cyrille"
set :runner,        "cyrille"
set :password,  "mavslr55"
set :deploy_to, "/var/rails/online_bookings"
set :rails_env, :production
set :db_user, "postgres"
set :db_name, "online_bookings_production"
set :db_password, "test0user"
# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end