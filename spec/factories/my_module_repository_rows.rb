FactoryBot.define do
  factory :mm_repository_row, class: MyModuleRepositoryRow do
    association :repository_row, factory: :repository_row
    association :my_module, factory: :my_module
  end
end
