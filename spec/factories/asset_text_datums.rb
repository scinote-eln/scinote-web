# frozen_string_literal: true

FactoryBot.define do
  factory :asset_text_datum do
    data { "Sample name\tSample type\n" + "sample6\tsample\n" + "\n" }
    asset
  end
end
