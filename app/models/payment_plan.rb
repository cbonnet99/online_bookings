class PaymentPlan < ActiveRecord::Base
  belongs_to :country
  has_many :payments
end
