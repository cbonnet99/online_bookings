module Clickatell #:nodoc:
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 8
    TINY  = 2

    STRING = [MAJOR, MINOR, TINY].join('.')
    
    def self.to_s
      STRING
    end
  end
end
