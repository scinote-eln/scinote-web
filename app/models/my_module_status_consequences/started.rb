# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusConsequences
  class Started < MyModuleStatusConsequence
    def forward(my_module)
      my_module.experiment.start! unless my_module.experiment.started?
      my_module.experiment.project.start! unless my_module.experiment.project.started?
    end
  end
end
