FactoryGirl.define do
  factory :repository_row do
    name 'Custom row'
    created_by { User.first || association(:user) }
    last_modified_by { User.first || association(:user) }
  end
end
