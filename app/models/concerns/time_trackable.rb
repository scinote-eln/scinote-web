# frozen_string_literal: true

module TimeTrackable
  extend ActiveSupport::Concern

  included do
    scope :not_started, -> { where(started_at: nil).where(completed_at: nil) }
    scope :started, -> { where.not(started_at: nil).where(completed_at: nil) }
    scope :completed, -> { where.not(completed_at: nil) }
  end

  def status=(status)
    case status.to_sym
    when :not_started
      self.started_at = nil
      self.completed_at = nil
    when :started
      self.completed_at = nil
      start
    when :completed
      complete
    else
      raise ArgumentError, 'Wrong status for TimeTrackable model!'
    end
  end

  def status
    if started_at.nil? && completed_at.nil?
      :not_started
    elsif started_at && !completed_at
      :started
    else
      :completed
    end
  end

  def not_started?
    started_at.blank? && completed_at.blank?
  end

  def not_started
    self.started_at = nil
    self.completed_at = nil
  end

  def not_started!
    update!(started_at: nil, completed_at: nil)
  end

  def started?
    started_at.present? && completed_at.blank?
  end

  def start
    self.started_at = DateTime.now
  end

  def start!
    update!(started_at: DateTime.now)
  end

  def completed?
    completed_at.present?
  end

  def complete
    self.completed_at = DateTime.now
  end

  def complete!
    update!(completed_at: DateTime.now)
  end
end
