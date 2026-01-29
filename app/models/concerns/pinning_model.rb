# frozen_string_literal: true

module PinningModel
  extend ActiveSupport::Concern

  included do
    scope :pinned, -> { where.not(pinned_at: nil) }
  end

  def pin!(user)
    self.pinned_by = user
    self.pinned_at = DateTime.now
    save!
  end

  def unpin!
    self.pinned_by = nil
    self.pinned_at = nil
    save!
  end

  def pinned?
    pinned_at.present?
  end
end
