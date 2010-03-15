require 'capistrano/ext/multistage'

set :application, "colibri"

set :scm_username,  "cbonnet99@gmail.com"
#set :scm_password,  lambda { CLI.password_prompt "SVN Password (user: #{scm_username}): "}
set :deploy_via, :remote_cache
# set :deploy_via,  :copy
set :scm, :git
#set :repository, "git://github.com/cbonnet99/cbba.git"
set :repository, "git@github.com:cbonnet99/online_bookings.git"
set :branch, "master"
set :git_enable_submodules, 1
ssh_options[:forward_agent] = true

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
  
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    # sudo "chown -R #{apache_user} #{shared_path}/geopip"
    unless File.exists?("#{shared_path}/geoip")
      run "mkdir #{shared_path}/geoip"
    end
    run "ln -nfs #{shared_path}/geoip #{release_path}/geoip"
  end  
  
  desc "Installs GeoIP"
  task :install_geoip do
    unless File.exists?("#{shared_path}/geoip/GeoLiteCity.dat")
      run "cd #{release_path} && script/update_geoip"
    end
  end
  
  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    if rails_env == :production
      puts "*** Deploying cron jobs"
      run "cd #{release_path} && whenever --update-crontab #{application}"
    else
      puts "*** No cron jobs deployed as the enviroment is NOT production, but #{rails_env}"
    end
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
    desc "Deploy will throw up the maintenance.html page and run migrations then it restarts and enables the site again."
    task :default do
      transaction do
        update_code
        web.disable
        symlink
        symlink_shared
        install_geoip
        migrate
        update_crontab
      end
      restart
      web.enable
      cleanup
    end
end

namespace :delayed_job do
  desc "Start delayed_job process" 
  task :start, :roles => :app do
    run "cd #{current_path}; script/delayed_job start #{rails_env}" 
  end

  desc "Stop delayed_job process" 
  task :stop, :roles => :app do
    run "cd #{current_path}; script/delayed_job stop #{rails_env}" 
  end

  desc "Restart delayed_job process" 
  task :restart, :roles => :app do
    run "cd #{current_path}; script/delayed_job restart #{rails_env}" 
  end
end

# after "deploy:start", "delayed_job:start" 
# after "deploy:stop", "delayed_job:stop" 
# after "deploy:restart", "delayed_job:restart"