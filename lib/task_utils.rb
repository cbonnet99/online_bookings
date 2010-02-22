class TaskUtils
  
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