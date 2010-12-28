class CountriesController < ApplicationController
  
  before_filter :get_country
  
  def mobile_phone_prefixes
    render :json => @country.mobile_phone_prefixes
  end

  def landline_phone_prefixes
    render :json => @country.landline_phone_prefixes
  end

private
  def get_country
        @country = Country.find(params[:id])
  end
end
