# frozen_string_literal: true

# Just an example, to be replaced with an actual implementation
module MyModuleStatusConditions
  class Active < MyModuleStatusCondition
    def call(my_module)
      my_module.errors.add(:status_conditions, I18n.t('my_module_statuses.conditions.error.my_module_not_active')) unless my_module.active?
    end

    def description
      I18n.t('my_module_statuses.conditions.error.my_module_not_active')
    end
  end
end
