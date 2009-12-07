class Client < ActiveRecord::Base
  
  has_many :bookings
  
  # new columns need to be added here to be writable through mass assignment
  attr_accessible :email, :password, :password_confirmation, :question, :answer
  
  attr_accessor :password
  before_save :prepare_password, :cleanup_phone
  
  validates_presence_of :email
  validates_uniqueness_of :email, :allow_blank => true
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  # validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  validates_length_of :password, :minimum => 4, :allow_blank => true

  MOBILE_SUFFIXES = ["021", "022", "027", "029"]
  FIXED_SUFFIXES = ["03", "04", "06", "07", "09"]
  PHONE_SUFFIXES = MOBILE_SUFFIXES + FIXED_SUFFIXES

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
  
  def has_mobile_phone
    MOBILE_SUFFIXES.include?(phone_prefix)
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
      self.password_salt = Digest::SHA1.hexdigest([Time.now, rand].join)
      self.password_hash = encrypt_password(password)
    end
  end
  
  def encrypt_password(pass)
    Digest::SHA1.hexdigest([pass, password_salt].join)
  end
end
