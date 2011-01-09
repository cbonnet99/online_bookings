class RemindersController < ApplicationController
  
  before_filter :login_required
  
  def index
    @selected_tab = "reminders"
    @reminders = current_pro.reminders.paginate :conditions => ["sent_at is null and sending_at >= ?", Time.now.in_time_zone(current_pro.timezone)],
                                   :page => params[:page], :order => "sending_at"
  end

  def index_past
    @selected_tab = "reminders"
    @reminders = current_pro.reminders.find(:all, :conditions => ["sent_at is not null and sending_at < ?", Time.now.in_time_zone(current_pro.timezone)], :order => "sending_at")
  end

end
