# frozen_string_literal: true

FactoryBot.define do
  factory :wopi_action do
    wopi_app
    action { 'random action' }
    urlsrc { 'www.wopi-action.com' }
    extension { 'random extension' }
  end
end
