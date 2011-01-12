set :output, "/var/log/cron_colibri.log"

every 5.minutes do
  runner "TaskUtils.end_bookings_grace_period"
  runner "UserEmail.send_unsent_emails"
end

every 1.hour do
  runner "TaskUtils.send_reminders"
end

every 1.day, :at => "3am"  do
  command "cp --preserve=timestamps /etc/apache2/sites-available/colibri_staging /home/cyrille/backups/apache-colibri_staging"
  command "cp --preserve=timestamps /etc/apache2/sites-available/colibri_production /home/cyrille/backups/apache-colibri_production"
  command "cp --preserve=timestamps /etc/nginx/sites-available/colibri_staging /home/cyrille/backups/nginx-colibri_staging"
  command "cp --preserve=timestamps /etc/nginx/sites-available/colibri_production /home/cyrille/backups/nginx-colibri_production"
  command "pg_dump -U colibri -d colibri_production > /home/cyrille/backups/colibri-backup-`date +\\%Y-\\%m-\\%d`.sql", :output => {:error => '/var/log/cron_colibri.log'}
  command "pg_dump -U postgres -d redmine_production > /home/cyrille/backups/redmine-backup-`date +\\%Y-\\%m-\\%d`.sql", :output => {:error => '/var/log/cron_colibri.log'}
end

every 1.day, :at => "6 pm" do
  runner "TaskUtils.send_pro_reminders"
end

every :month do
  command "/var/rails/colibri_production/current/script/update_geoip"
end 