class TaskUtils
  PRO_ARRAYS = [["Cyrille", "Bonnet", "cb@gmail.com", "04 34 55 45 23"], ["Kartini", "Thomas", "kt@gmail.com", "04 34 55 45 11"]]
  FIRST_NAMES = ["Roger", "Oliver", "Susan", "Jeff", "Isabel", "Beth", "Lorelei", "Tadeo"]
  LAST_NAMES = ["Yi", "Aloha", "Jones", "Salvador", "Lanta", "Spaniel", "Humbri", "Lavaur", "Pujol"]
  DOMAINS = ["gmail.com", "test.com", "info.org"]
  BOOKING_STATES = ["unconfirmed", "confirmed" ,"cancelled"]
  
  def self.wipe_data
    Booking.delete_all
    Client.delete_all
    Practitioner.delete_all
  end
  
  def self.create_sample_data
    Time.zone = "Paris"
    #2 pros
    pros = []
    PRO_ARRAYS.each do |pro_array|
      pro = Practitioner.new(:first_name => pro_array[0], :last_name => pro_array[1], :timezone => "Paris",
          :country_code => "FR", 
          :email => pro_array[2], :password => pro_array[0][0,4], :password_confirmation => pro_array[0][0,4],
          :working_hours => "8-18", :working_days => "1,2,3,4,5", :no_cancellation_period_in_hours => Practitioner::DEFAULT_CANCELLATION_PERIOD,
          :phone => pro_array[3])
      pro.save!
      pros << pro
    end
    
    #30 clients
    clients = []
    30.times do
        first_name = FIRST_NAMES[rand(FIRST_NAMES.size)]
      last_name = LAST_NAMES[rand(LAST_NAMES.size)]
      all_client_names = clients.map(&:name)
      while (all_client_names.include?("#{first_name} #{last_name}"))
        puts "#{first_name} #{last_name} is taken, trying again"
        first_name = FIRST_NAMES[rand(FIRST_NAMES.size)]
        last_name = LAST_NAMES[rand(LAST_NAMES.size)]
      end
      puts "+++++ Creating client #{first_name} #{last_name}"
      email = "#{first_name}.#{last_name}@#{DOMAINS[rand(DOMAINS.size)]}"
      client = Client.new(:first_name => first_name, :last_name => last_name, :phone_prefix  => "06",
          :phone_suffix => "#{rand(99)} #{rand(99)} #{rand(99)} #{rand(99)}", 
          :email => email, :password => first_name[0,4], :password_confirmation => first_name[0,4]  )
      client.save!
      clients << client
    end
    
    #150 appointments in the past
    150.times do
      days_ago = rand(200)
      date = Time.now.advance(:days => -days_ago).to_date
      while (date.wday == 0 || date.wday == 6) do
        #try again if it's a Saturday or Sunday
        days_ago = rand(200)
        date = Time.now.advance(:days => -days_ago).to_date        
      end
      start_hour = rand(10)+8
      starts_at = DateTime.strptime("#{date.strftime('%d/%m/%Y')} #{start_hour}:00 CEST", "%d/%m/%Y %H:%M %Z")
      client = clients[rand(clients.size)]
      booking = Booking.new(:client => client, :practitioner => pros[rand(pros.size)], :name => client.name, 
          :starts_at => starts_at, :ends_at  => starts_at.advance(:hours => 1), :state => BOOKING_STATES[rand(BOOKING_STATES.size)])
      booking.save!
    end
    
    #150 appointments in the future
    150.times do
      days = rand(200)
      date = Time.now.advance(:days => days).to_date
      while (date.wday == 0 || date.wday == 6) do
        #try again if it's a Saturday or Sunday
        days_ago = rand(200)
        date = Time.now.advance(:days => days_ago).to_date        
      end
      starts_at = DateTime.strptime("#{date.strftime('%d/%m/%Y')} #{rand(10)+8}:00 CEST", "%d/%m/%Y %H:%M %Z")
      client = clients[rand(clients.size)]
      booking = Booking.new(:client => client, :practitioner => pros[rand(pros.size)], :name => client.name, 
          :starts_at => starts_at, :ends_at  => starts_at.advance(:hours => 1), :state => BOOKING_STATES[rand(BOOKING_STATES.size)])
      booking.save!
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