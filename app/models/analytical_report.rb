# frozen_string_literal: true

class AnalyticalReport < ApplicationRecord
  belongs_to :reference, polymorphic: true
  belongs_to :report_template, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  enum :generating_status, { done: 0, in_progress: 1, failed: 2 }

  has_one_attached :report

  after_update :broadcast_generating_status_change, if: :saved_change_to_generating_status?

  private

  def broadcast_generating_status_change
    if reference.is_a?(MyModule)
      MyModuleReportGenerationsChannel.broadcast_to(reference, generating_report: generating_status == :done, report_template_id: report_template.id)
    elsif reference.is_a?(Experiment)
      ExperimentReportGenerationsChannel.broadcast_to(reference, generating_report: generating_status == :done)
    end
  end
end
