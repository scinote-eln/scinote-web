# frozen_string_literal: true

class ReportTemplate < ApplicationRecord
  belongs_to :subject, polymorphic: true

  has_one_attached :odt_template_file
  has_one_attached :docx_template_file
  has_one_attached :odt_template_file_preview

  after_update :broadcast_generating_report_change, if: :saved_change_to_generating_report?

  def generate_preview!
    ReportTemplates::ReportTemplatePreviewJob.perform_later(id)
  end

  def self.analytical_reporting_enabled?
    ApplicationSettings.instance.values['analytical_reporting_enabled'] == true
  end

  private

  def broadcast_generating_report_change
    MyModuleReportGenerationsChannel.broadcast_to(subject&.my_module, generating_report: generating_report, id: id) if subject&.my_module
  end
end
