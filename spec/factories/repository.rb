FactoryBot.define do
  factory :repository do
    name 'My Repository'
    created_by { User.first || create(:user) }
    team { Team.first || create(:team) }
  end
end
