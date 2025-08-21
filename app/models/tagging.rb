# frozen_string_literal: true

class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true, inverse_of: :taggings
  belongs_to :created_by, class_name: 'User', optional: true

  validates :tag_id, uniqueness: { scope: :taggable }
end
