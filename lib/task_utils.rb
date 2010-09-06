class TaskUtils
  PRO_ARRAYS = [["Cyrille", "Bonnet", "cb@gmail.com", "04 34 55 45 23"], ["Kartini", "Thomas", "kt@gmail.com", "04 34 55 45 11"]]
  
  def self.wipe_data
    Booking.delete_all
    Client.delete_all
    Practitioner.delete_all
  end
  
  def self.create_sample_data
    Time.zone = "Paris"
    #2 pros
    PRO_ARRAYS.each do |pro_array|
      pro = Practitioner.new(:first_name => pro_array[0], :last_name => pro_array[1], :timezone => "Paris",
          :country_code => "FR", 
          :email => pro_array[2], :password => pro_array[0][0,4], :password_confirmation => pro_array[0][0,4],
          :working_hours => "8-18", :working_days => "1,2,3,4,5", :no_cancellation_period_in_hours => Practitioner::DEFAULT_CANCELLATION_PERIOD,
          :phone => pro_array[3])
      pro.save!
      pro.create_sample_data!
    end    
  end
  
  def self.send_reminders
    Booking.need_reminders.each do |booking|
      puts "Sending reminder to: #{booking.client.name} for appointment at #{booking.starts_at}"
      booking.send_reminder!
    end
  end
  
  def self.send_pro_reminders
    Practitioner.need_reminders.each do |pro|
      puts "Sending PRO reminder to: #{pro.name}"
      pro.send_reminder!
    end    
  end
  
end