# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusImplications
  class ReadOnly < MyModuleStatusImplication
    def call(my_module)
      my_module.errors.add(:status_implication, 'Is read only')
      false
    end
  end
end
