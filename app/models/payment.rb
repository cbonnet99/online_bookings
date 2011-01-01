class Payment < ActiveRecord::Base
  
  include AASM
  
  belongs_to :payment_plan
  belongs_to :practitioner
  attr_accessor :card_number, :card_verification, :store_card, :stored_token_id
  attr_accessible :payment_plan, :payment_plan_id, :address1, :city, :card_verification, :card_number, :card_expires_on,
                  :last_name, :first_name

  validate_on_create :validate_card

  validates_presence_of :payment_plan

  before_save :set_amount
  
  aasm_column :status
  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :completed

  aasm_event :complete do
    transitions :from => :pending, :to => :completed
  end
  
  
  def finalize!
    #create_invoice
    self.practitioner.activate! unless self.practitioner.active?
    self.practitioner.update_attribute(:sms_credit, self.payment_plan.sms_credit)
  end
  
  def set_amount
    self.amount = payment_plan.try(:amount)
    self.currency = self.practitioner.country.currency
  end
  
  def purchase!
    if self.stored_token_id.nil?
      if self.store_card == "1"
        token = user.stored_tokens.create(:card_number => card_number, :first_name => first_name, :last_name => last_name, :last4digits => last4digits, :card_expires_on => card_expires_on.end_of_month)
      end
      response = GATEWAY.purchase(self.amount, credit_card, purchase_options)
    else
      token = self.user.stored_tokens.find(self.stored_token_id)
      if token.nil?
        return ErrorResponse.new("No token for ID: #{self.stored_token_id}")
      else
        response = GATEWAY.purchase(self.amount, token.billing_id , purchase_options)
      end
    end
    logger.debug "============ response from DPS purchase: #{response.inspect}"
    if response.success?
      self.complete!
      self.reload
      self.finalize!
    end
    return response    
  end

  def purchase_options
    {
      :ip => ip_address,
      :description => "#{practitioner.email} - #{payment_plan.try(:title)}",
      :billing_address => {
        :name     => "#{first_name} #{last_name}",
        :address1 => address1,
        :city     => city,
        :country  => "NZ"
      }
    }
  end
  
  def validate_card
    unless !self.stored_token_id.nil? || credit_card.valid?
      credit_card.errors.full_messages.each do |message|
        errors.add_to_base message
      end
    end
  end

  def credit_card
    @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
      :type               => card_type,
      :number             => card_number,
      :verification_value => card_verification,
      :month              => card_expires_on.month,
      :year               => card_expires_on.year,
      :first_name         => first_name,
      :last_name          => last_name
    )
  end
  
end
