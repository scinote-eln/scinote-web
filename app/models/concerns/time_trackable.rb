# frozen_string_literal: true

module TimeTrackable
  extend ActiveSupport::Concern

  STATUS_ORDER = %i(not_started in_progress done).freeze

  included do
    scope :not_started, -> { where(started_at: nil).where(done_at: nil) }
    scope :in_progress, -> { where.not(started_at: nil).where(done_at: nil) }
    scope :done, -> { where.not(done_at: nil) }
  end

  def status=(status)
    case status.to_sym
    when :not_started
      self.started_at = nil
      self.done_at = nil
    when :in_progress
      self.done_at = nil
      start
    when :done
      complete
    else
      raise ArgumentError, 'Wrong status for TimeTrackable model!'
    end
  end

  def status
    compute_status(started_at, done_at)
  end

  def status_was
    compute_status(started_at_before_last_save, done_at_before_last_save)
  end

  def not_started?
    started_at.blank? && done_at.blank?
  end

  def not_started
    self.started_at = nil
    self.done_at = nil
  end

  def not_started!
    update!(started_at: nil, done_at: nil)
  end

  def started?
    started_at.present? && done_at.blank?
  end

  def start
    self.started_at = DateTime.now
  end

  def start!
    update!(started_at: DateTime.now)
  end

  def done?
    done_at.present?
  end

  def complete
    self.done_at = DateTime.now
  end

  def complete!
    update!(done_at: DateTime.now)
  end

  def status_moved_forward?
    return false unless started_at_previously_changed? || done_at_previously_changed?

    STATUS_ORDER.index(status) > STATUS_ORDER.index(status_was)
  end

  private

  def compute_status(started_at_value, done_at_value)
    if started_at_value.nil? && done_at_value.nil?
      :not_started
    elsif started_at_value && !done_at_value
      :in_progress
    else
      :done
    end
  end
end
