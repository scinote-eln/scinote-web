# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusConsequences
  class Completion < MyModuleStatusConsequence
    def forward(my_module)
      my_module.state = 'completed'
      my_module.completed_on = DateTime.now
      my_module.save!
    end
  end
end
