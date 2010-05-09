class ExtraWorkingDaysController < ApplicationController
  before_filter :login_required
  layout false
  
  def create
    new_day = ExtraWorkingDay.new(params[:extra_working_day])
    new_day.practitioner_id = current_pro.id
    if new_day.save
      flash[:notice] = "An additional working day has been created"
    else
      flash[:error] = "There was an error while creating an additional working day "
    end
  end
end
