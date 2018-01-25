FactoryBot.define do
  factory :team do
    created_by { User.first || create(:user) }
    name 'My team'
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing eli.'
    space_taken 1048576
  end
end
