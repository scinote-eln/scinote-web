# frozen_string_literal: true

class EditingFlag < ApplicationRecord
  DEFAULT_DURATION = 30.seconds

  belongs_to :user
  belongs_to :subject, polymorphic: true

  validates :timeout_at, presence: true
  validates :user_id, uniqueness: { scope: %i(subject_type subject_id) }

  scope :active, -> { where(timeout_at: Time.current..) }
  scope :expired, -> { where(timeout_at: ...Time.current) }

  after_commit :broadcast_create, on: :create, if: :subject_present?
  after_commit :broadcast_refresh, on: :update, if: -> { saved_change_to_timeout_at? && subject_present? }
  after_commit :broadcast_destroy, on: :destroy, if: :subject_present?

  private

  # The subject (e.g. a StepText) may have been deleted while this flag was still active -
  # nothing cascades that deletion to here, so broadcasting would try to stream to a nil
  # subject and raise. Skip it; the orphaned row still expires and gets cleaned up normally.
  def subject_present?
    subject.present?
  end

  def broadcast_create
    EditingFlagsChannel.broadcast_to(subject, action: 'create', editing_flag: broadcast_payload)
  end

  def broadcast_refresh
    EditingFlagsChannel.broadcast_to(subject, action: 'refresh', editing_flag: broadcast_payload)
  end

  def broadcast_destroy
    EditingFlagsChannel.broadcast_to(subject, action: 'destroy', editing_flag: broadcast_payload)
  end

  def broadcast_payload
    ActiveModelSerializers::SerializableResource.new(self, serializer: EditingFlagSerializer).as_json
  end
end
