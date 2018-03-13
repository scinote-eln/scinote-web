FactoryBot.define do
  factory :repository_asset_value do
    created_by { User.first || create(:user) }
    last_modified_by { User.first || create(:user) }
  end
end
