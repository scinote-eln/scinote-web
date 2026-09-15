# frozen_string_literal: true

class ReportTemplate < ApplicationRecord
  belongs_to :subject, polymorphic: true
  has_many :analytical_reports, dependent: :nullify

  has_one_attached :odt_template_file
  has_one_attached :docx_template_file
  has_one_attached :odt_template_file_preview

  def generate_preview!
    ReportTemplates::ReportTemplatePreviewJob.perform_later(id)
  end

  def preview_status
    return :ready if odt_template_file_preview.attached?
    return :failed if preview_failed?
    return :not_previewable if odt_template_file.attached? && !ActiveStorageFileUtil.previewable_document?(odt_template_file.blob)

    :processing
  end

  def preview_failed?
    [docx_template_file, odt_template_file].any? do |attachment|
      attachment.attached? && attachment.blob.metadata['preview_failed'].present?
    end
  end

  def self.analytical_reporting_enabled?
    ApplicationSettings.instance.values['analytical_reporting_enabled'] == true
  end
end
