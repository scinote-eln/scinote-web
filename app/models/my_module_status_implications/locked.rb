# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusImplications
  class Locked < MyModuleStatusImplication
    def call(my_module)
      my_module.errors.add(:status_implication, 'Is locked')
      false
    end
  end
end
