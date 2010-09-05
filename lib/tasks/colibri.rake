namespace :colibri do

  desc "Creates sample data"
  task :sample_data => :environment do
    unless ENV["RAILS_ENV"] == "production"
      TaskUtils.create_sample_data
    end
  end
  desc "Wipes all bookings, clients and practitioners (does nothing in production...)"
  task :wipe_data => :environment do
    unless ENV["RAILS_ENV"] == "production"
      TaskUtils.wipe_data
    end
  end
end