module Permalinkable
  def self.included(base)

    base.send :include, WorkflowInstanceMethods
    base.send :extend, WorkflowClassMethods
    base.send :before_create, :create_permalink
    base.send :before_update, :create_permalink
  end
  
  module WorkflowClassMethods
  end
  
  module WorkflowInstanceMethods
    def to_param
      self.permalink
    end

  	def create_permalink
  		self.permalink = computed_permalink
  	end

  	def computed_permalink
  	  if respond_to?(:full_name)
  	    full_name.parameterize
	    else
  		  name.parameterize
		  end
  	end    
  end
end