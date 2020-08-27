# frozen_string_literal: true

FactoryBot.define do
  factory :read_only_implication, class: 'MyModuleStatusImplications::ReadOnly' do
    my_module_status
  end
end
