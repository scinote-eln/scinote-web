# frozen_string_literal: true

class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :team
  belongs_to :item, polymorphic: true
end
