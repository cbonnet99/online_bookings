class WorkingDaysController < ApplicationController
  before_filter :login_required
  layout false
  
  def create
    new_day = ExtraWorkingDay.new(params[:extra_working_day])
    new_day.practitioner_id = current_pro.id
    if new_day.save
      flash[:notice] = "Your calendar has been changed: you are now available for appointments on #{new_day.day_date.to_s(:long)}"
    else
      flash[:error] = "There was an error while changing your calendar: #{new_day.errors.full_messages.to_sentence}"
    end
  end
  
  def destroy
    day_to_destroy = current_pro.extra_working_days.find(params[:id])
    if day_to_destroy.nil?
      flash[:error] = "Sorry, there was an internal error: extra working day ID #{params[:id]} cannot be found"
    else
      if day_to_destroy.has_bookings?
        flash[:error] = "Sorry, you have appointments on #{day_to_destroy.day_date.to_s(:long)}: you will have to move or remove them"
      else
        deleted_date = day_to_destroy.day_date
        day_to_destroy.destroy
        flash[:notice] = "Your calendar has been changed: you are not available for appointments on #{deleted_date.to_s(:long)} anymore"
      end
    end
  end
end
