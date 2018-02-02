FactoryBot.define do
  factory :sample_group do
    name 'Sample'
    color '#ff00ff'
    team { Team.first || create(:team) }
  end
end
