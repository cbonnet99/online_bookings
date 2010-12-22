class PaymentsController < ApplicationController
  before_filter :require_selected_practitioner

  def new
    @plans = @current_pro.country.try(:payment_plans)
  end
end
