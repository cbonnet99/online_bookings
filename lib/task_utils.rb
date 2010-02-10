class TaskUtils
  
  def self.send_reminders
    Booking.need_reminders.each do |booking|
      booking.send_reminder!
    end
  end
  
end