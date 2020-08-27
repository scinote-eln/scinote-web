# frozen_string_literal: true

FactoryBot.define do
  factory :change_activity_consequence, class: 'MyModuleStatusConsequences::ChangeActivity' do
    my_module_status
  end
end
