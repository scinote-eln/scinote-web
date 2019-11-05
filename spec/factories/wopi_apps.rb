# frozen_string_literal: true

FactoryBot.define do
  factory :wopi_app do
    sequence(:name) { |n| "WopiApp-#{n}" }
<<<<<<< HEAD
<<<<<<< HEAD
    icon { 'app-icon' }
=======
    icon 'app-icon'
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    icon { 'app-icon' }
>>>>>>> Initial commit of 1.17.2 merge
    wopi_discovery
  end
end
