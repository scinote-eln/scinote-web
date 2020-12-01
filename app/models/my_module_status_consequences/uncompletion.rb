# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusConsequences
  class Uncompletion < MyModuleStatusConsequence
    def backward(my_module)
      return unless my_module.state == 'completed'

      my_module.state = 'uncompleted'
      my_module.completed_on = nil
      my_module.save!
    end
  end
end
