# frozen_string_literal: true

FactoryBot.define do
  factory :active_condition, class: 'MyModuleStatusConditions::Active' do
    my_module_status
  end
end
