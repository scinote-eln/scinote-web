# frozen_string_literal: true

FactoryBot.define do
  factory :wopi_app do
    sequence(:name) { |n| "WopiApp-#{n}" }
<<<<<<< HEAD
    icon { 'app-icon' }
=======
    icon 'app-icon'
>>>>>>> Finished merging. Test on dev machine (iMac).
    wopi_discovery
  end
end
