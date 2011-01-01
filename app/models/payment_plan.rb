class PaymentPlan < ActiveRecord::Base
  belongs_to :country
  has_many :payments
  
  def price_display
    s = amount.to_s
    price = "#{s[0..-3]}.#{s.slice(-2, 2)}"
    if self.country.currency_before?
      return "#{self.country.currency_symbol}#{price}"
    else
      return "#{price} #{self.country.currency_symbol}"
    end
  end
end
