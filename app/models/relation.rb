class Relation < ActiveRecord::Base
  belongs_to :practitioner
  belongs_to :client
end
