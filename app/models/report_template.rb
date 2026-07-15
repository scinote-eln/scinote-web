# frozen_string_literal: true

class ReportTemplate < ApplicationRecord
  belongs_to :subject, polymorphic: true

  has_one_attached :odt_template_file
  has_one_attached :docx_template_file
  has_one_attached :odt_template_file_preview

  def generate_preview!
    ReportTemplates::ReportTemplatePreviewJob.perform_later(id)
  end

  def self.analytical_reporting_enabled?
    ApplicationSettings.instance.values['analytical_reporting_enabled'] == true
  end
end
