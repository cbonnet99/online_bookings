module BookingsHelper

  def sharing_ical
    !current_pro.nil? && !current_pro.bookings_publish_code.blank?
  end
end
