class TaskUtils

  def self.end_bookings_grace_period
    Booking.ending_grace_period.each do |b|
      b.end_grace_period!
    end
  end
  
  def self.delete_sample_data
    unless Rails.env.production?
      Practitioner.test_user.each do |p|
        p.delete_sample_data!
      end
    end
  end
  
  def self.time_to_recreate_test_user?(number_clients=30, number_bookings=150)
    Country.all.each do |country|
      Time.zone = country.default_timezone
      all_test_users = country.practitioners.test_user
      if all_test_users.size > 1
        logger.error("Country: #{country.name} has #{all_test_users.size} demo users. It should only have one! I will delete them all and recreate one now.")
        country.recreate_test_user(number_clients, number_bookings)
      else
        if all_test_users.size == 0
          country.recreate_test_user(number_clients, number_bookings)
        else
          test_user = all_test_users.first
          if test_user.created_at + 24.hours < Time.zone.now
            country.recreate_test_user(number_clients, number_bookings)
          else
            just_past_midnight = Time.zone.now.strftime("%H") == "00"
            if just_past_midnight
              country.recreate_test_user(number_clients, number_bookings)
            end
          end
        end
      end
    end
  end
  
  def self.create_sample_data(number_clients=30, number_bookings=150)
    Country.all.each do |country|
      country.recreate_test_user(number_clients, number_bookings)
    end    
  end
    
  def self.send_reminders
    Reminder.need_sending.each do |r|
      puts "Sending reminder to: #{r.booking.client.name} for appointment at #{r.booking.starts_at}"
      r.send!
    end
  end
  
  def self.send_pro_reminders
    Practitioner.need_reminders.each do |pro|
      puts "Sending PRO reminder to: #{pro.name}"
      pro.send_reminder!
    end    
  end
  
end