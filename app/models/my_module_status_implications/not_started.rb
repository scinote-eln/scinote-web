# frozen_string_literal: true

# This implication just shows that a task hasn't been started yet
module MyModuleStatusImplications
  class NotStarted < MyModuleStatusImplication
    def call(_my_module)
      true
    end
  end
end
