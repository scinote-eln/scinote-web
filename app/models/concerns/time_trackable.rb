# frozen_string_literal: true

module TimeTrackable
  extend ActiveSupport::Concern

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
    if started_at.nil? && done_at.nil?
      :not_started
    elsif started_at && !done_at
      :in_progress
    else
      :done
    end
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
end
