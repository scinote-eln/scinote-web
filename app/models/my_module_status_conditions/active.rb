# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusConditions
  class Active < MyModuleStatusCondition
    def call(my_module)
      my_module.errors.add(:status_conditions, 'MyModule should be active') unless my_module.active?
    end

    def description
      'MyModule should be active'
    end
  end
end
