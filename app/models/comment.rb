# frozen_string_literal: true

class Comment < ApplicationRecord
  include SearchableModel

  SEARCHABLE_ATTRIBUTES = ['comments.message'].freeze

  auto_strip_attributes :message, nullify: false
  validates :message,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }

  belongs_to :user, inverse_of: :comments
  belongs_to :last_modified_by, class_name: 'User', inverse_of: :comments, optional: true

  scope :unseen_by, ->(user) { where('? = ANY (unseen_by)', user.id) }

  def self.mark_as_seen_by(user)
    # rubocop:disable Rails/SkipsModelValidations
    where('? = ANY (unseen_by)', user.id).update_all("unseen_by = array_remove(unseen_by, #{user.id.to_i}::bigint)")
    # rubocop:enable Rails/SkipsModelValidations
  end
end
