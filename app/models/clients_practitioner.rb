class ClientsPractitioner < ActiveRecord::Base
  belongs_to :client
  belongs_to :practitioner
end
