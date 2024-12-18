# frozen_string_literal: true

FactoryBot.define do
  factory :form_field_value do
    type { 'FormFieldTextValue' }
    text { 'hello' }
    association :form_response
    association :form_field
    association :created_by, factory: :user
    association :submitted_by, factory: :user
  end
end
