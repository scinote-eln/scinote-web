class Comment < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :message, nullify: false
  validates :message,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :user, presence: true

  belongs_to :user, inverse_of: :comments
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true

  scope :unseen_by, ->(user) { where('? = ANY (unseen_by)', user.id) }

  def self.mark_as_seen_by(user, commentable)
    # rubocop:disable Rails/SkipsModelValidations
    all.where('? = ANY (unseen_by)', user.id).update_all("unseen_by = array_remove(unseen_by, #{user.id.to_i}::bigint)")

    # Because we want the number of unseen comments to affect the cache of project
    # and experiment lists, we need to set the updated_at of Project or Experiment.
    commentable.touch if commentable.class.in? [Project, Experiment]

    # rubocop:enable Rails/SkipsModelValidations
  end
end
