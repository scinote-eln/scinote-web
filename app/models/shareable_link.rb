# frozen_string_literal: true

class ShareableLink < ApplicationRecord
  validates :shareable_type, uniqueness: { scope: :shareable_id }
  validates :description, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }

  belongs_to :shareable, polymorphic: true, inverse_of: :shareable_link
  belongs_to :team
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User', optional: true
end
