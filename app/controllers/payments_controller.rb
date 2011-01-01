class PaymentsController < ApplicationController
  before_filter :require_selected_practitioner

  def new
    @plans = @current_pro.country.try(:payment_plans)
    @default_plan = @plans.select{|p| p.highlighted?}.first
    @payment = Payment.new
    @payment.first_name = @current_pro.first_name
    @payment.last_name = @current_pro.last_name
    @payment.store_card = true
  end
  
  def create
    if params["cancel"]
      flash[:notice] = I18n.t(:payment_cancelled)
      redirect_to practitioner_url(@current_pro.permalink)
    else
      @payment = Payment.new(params[:payment])
      @payment.ip_address = request.remote_ip
      @payment.practitioner_id = @current_pro.id
      if @payment.save
        @gateway_response = @payment.purchase!
        if !@gateway_response.nil? && @gateway_response.success?
          flash[:notice] = I18n.t(:payment_thanks)
          redirect_to practitioner_url(@current_pro.permalink)
        else
          flash.now[:error] = "#{I18n.t(:payment_problem)}: #{@gateway_response.try(:message)}"
          @plans = @current_pro.country.try(:payment_plans)
          render :action => 'new'
        end
      else
        flash.now[:error] = I18n.t(:payment_problem)
        @plans = @current_pro.country.try(:payment_plans)
        render :action => 'new'        
      end
    end    
  end
  
end
