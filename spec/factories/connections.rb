# frozen_string_literal: true

FactoryBot.define do
  factory :connection do
    from { create :my_module }
    to { create :my_module }
  end
end
