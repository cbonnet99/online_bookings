class Payment < ActiveRecord::Base
  belongs_to :payment_plan
end
