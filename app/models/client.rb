class Client < ActiveRecord::Base
  
  RE_EMAIL = /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  DEFAULT_EMAIL_TEXT = "You can now book appointments with me online at ColibriApp.com by clicking on the following link:\n"
  DEFAULT_EMAIL_SIGNOFF = "Regards,"
  
  has_many :bookings
  has_many :reminders, :through => :bookings 
  has_many :client_emails
  has_many :relations
  has_many :practitioners, :through => :relations
  has_many :user_emails
  belongs_to :country
  
  # new columns need to be added here to be writable through mass assignment
  attr_accessible :first_name, :last_name, :email, :password, :password_confirmation, :phone_prefix, :phone_suffix, :name
  
  attr_accessor :password
  before_save :prepare_password
  before_validation :cleanup_phone
  
  validates_uniqueness_of :email, :allow_blank => true
  validates_format_of :email, :with => RE_EMAIL
  validates_length_of :phone_prefix, :within => 2..3, :allow_blank => true
  # validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  validates_length_of :password, :minimum => 4, :allow_blank => true
  
  PHONE_SUFFIX_MIN = 7
  PHONE_SUFFIX_MAX = 12
  
  def validate
    if email.blank? && phone_prefix.blank? && phone_suffix.blank?
      errors.add(:email, I18n.t(:client_email_or_phone_must_not_be_blank))
    end
    if phone_suffix.blank? && !phone_prefix.blank?
      errors.add(:phone_suffix, I18n.t(:invalid_phone_number))
    end
    if !phone_suffix.blank? && phone_prefix.blank?
      errors.add(:phone_prefix, I18n.t(:invalid_phone_number))
    end
    unless phone_suffix.blank?
      if phone_suffix.size > PHONE_SUFFIX_MAX
        errors.add(:phone_suffix, I18n.t(:phone_number_too_long, :max => PHONE_SUFFIX_MAX))
      end
      if phone_suffix.size < PHONE_SUFFIX_MIN
        errors.add(:phone_suffix, I18n.t(:phone_number_too_short, :min => PHONE_SUFFIX_MIN))
      end
    end
  end
  
  def name=(new_name)
    unless new_name.nil?
      split_names = new_name.split(' ')
      self.first_name = split_names[0..split_names.size-2].join(" ")
      self.last_name = split_names[split_names.size-1]
    end
  end
  
  def update_booking(booking, hash_booking, current_client, current_selected_pro)
    booking.client_id = current_client.id
    booking.practitioner_id = current_selected_pro.id
    booking.name = current_client.default_name if booking.name.blank?
    booking.current_client = current_client
    hash_booking.delete("practitioner_id")
    hash_booking.delete("client_id")
    return booking, hash_booking
  end

  def self.valid_email?(email)
    email.match(RE_EMAIL)
  end
  
  def first_name_or_email
    if first_name.blank?
      email
    else
      first_name
    end
  end
    
  def default_name
    if name.blank?
      email
    else
      name
    end
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def name_and_email
    if first_name.blank? && last_name.blank?
      "#{email}"
    else
      "#{first_name} #{last_name} (#{email})"
    end
  end

  def send_reset_phone_link
    self.reset_code = Digest::SHA1.hexdigest("#{email}#{Time.zone.now}#{id}")
    self.save!
    UserMailer.deliver_reset_phone(self)
  end

  def no_phone_number?
    self.phone.blank? || self.phone == "-"
  end

  def check_phone_first_4digits(last4_digits)
    !phone_suffix.nil? && phone_suffix[-4..phone_suffix.length] == last4_digits
  end
  
  def cleanup_phone
    self.phone_prefix = self.phone_prefix.gsub(/[ -\/]/, '') unless phone_prefix.nil?
    self.phone_suffix = self.phone_suffix.gsub(/[ -\/]/, '') unless phone_suffix.nil?
  end
  
  def phone_without_last4digits
    "#{phone_prefix}-#{phone_suffix[0..-5]}"
  end
  
  def phone
    "#{phone_prefix}-#{phone_suffix}"
  end
  
  def mobile_phone_prefixes
    self.country.mobile_phone_prefixes
  end
  
  def landline_phone_prefixes
    self.country.landline_phone_prefixes
  end  
  
  def phone_prefixes
    mobile_phone_prefixes + landline_phone_prefixes
  end
  
  def has_mobile_phone?
    mobile_phone_prefixes.include?(phone_prefix)
  end
  
  def self.authenticate(login, pass)
    client = find_by_email(login)
    return client if client && client.matching_password?(pass)
  end
  
  def matching_password?(pass)
    self.password_hash == encrypt_password(pass)
  end
  
  private
  
  def prepare_password
    unless password.blank?
      self.password_salt = Digest::SHA1.hexdigest([Time.zone.now, rand].join)
      self.password_hash = encrypt_password(password)
    end
  end
  
  def encrypt_password(pass)
    Digest::SHA1.hexdigest([pass, password_salt].join)
  end
end
