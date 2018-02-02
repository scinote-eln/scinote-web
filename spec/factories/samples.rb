FactoryBot.define do
  factory :sample do
    name 'Sample'
    user { User.first || create(:user) }
    team { Team.first || create(:team) }
  end
end
