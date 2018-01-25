FactoryBot.define do
  factory :asset do
    association :created_by, factory: :project_user
    association :team, factory: :team
    file_file_name 'sample_file.txt'
    file_content_type 'text/plain'
    file_file_size 69
    version 1
    estimated_size 232
    file_processing false
  end
end
