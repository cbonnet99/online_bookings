namespace :colibri do

  desc "Creates sample data"
  task :sample_data => :environment do
    unless ENV["RAILS_ENV"] == "production"
      TaskUtils.create_sample_data
    end
  end
  desc "Deletes all bookings, clients and practitioners for test users (does nothing in production...)"
  task :delete_sample_data => :environment do
    unless ENV["RAILS_ENV"] == "production"
      TaskUtils.delete_sample_data
    end
  end
end