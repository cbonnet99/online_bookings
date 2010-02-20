class TaskUtils
  
  def self.send_reminders
    Booking.need_reminders.each do |booking|
      puts "Sending reminder to: #{booking.client.name} for appointment at #{booking.start_at}"
      booking.send_reminder!
    end
  end
  
end