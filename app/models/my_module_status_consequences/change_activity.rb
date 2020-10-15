# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusConsequences
  class ChangeActivity < MyModuleStatusConsequence
    def call(my_module)
      # Create new activity here
      puts "State changed to #{my_module_status.name}} for #{my_module.name}"
    end
  end
end
