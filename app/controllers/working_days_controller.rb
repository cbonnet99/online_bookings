class WorkingDaysController < ApplicationController
  before_filter :login_required
  layout false
  
  def create
    non_working_day = current_pro.extra_non_working_day(params[:day_date])
    if non_working_day.nil?
      new_day = ExtraWorkingDay.new(:day_date => params[:day_date])
      new_day.practitioner_id = current_pro.id
      if new_day.save
        flash[:notice] = "Your calendar has been changed: you are now available for appointments on #{new_day.day_date.to_s(:long)}"
      else
        flash[:error] = "There was an error while changing your calendar: #{new_day.errors.full_messages.to_sentence}"
      end
    else
      deleted_date = non_working_day.day_date
      non_working_day.destroy
      flash[:notice] = "Your calendar has been changed: you are now available for appointments on #{deleted_date.to_s(:long)}"
    end
  end
  
  def destroy
    working_day = current_pro.extra_working_day(params[:day_date])
    if working_day.nil?
      if current_pro.has_bookings_on?(params[:day_date])
        flash[:error] = "Sorry, you have appointments on #{working_day.day_date.to_s(:long)}: you will have to move or remove them"
      else
        new_non_day = ExtraNonWorkingDay.new(:day_date => params[:day_date])
        new_non_day.practitioner_id = current_pro.id
        if new_non_day.save
          flash[:notice] = "Your calendar has been changed: you are not available for appointments on #{new_day.day_date.to_s(:long)} anymore"
        else
          flash[:error] = "There was an error while changing your calendar: #{new_day.errors.full_messages.to_sentence}"
        end
      end
    else
      if current_pro.has_bookings_on?(working_day.day_date)
        flash[:error] = "Sorry, you have appointments on #{working_day.day_date.to_s(:long)}: you will have to move or remove them"
      else
        deleted_date = working_day.day_date
        working_day.destroy
        flash[:notice] = "Your calendar has been changed: you are not available for appointments on #{deleted_date.to_s(:long)} anymore"
      end
    end
  end
end
