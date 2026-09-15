# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportTemplate, type: :model do
  let(:protocol) { create(:protocol) }
  let(:report_template) { create(:report_template, subject: protocol) }

  describe '#preview_status' do
    it 'returns processing when neither odt file nor preview are attached' do
      expect(report_template.preview_status).to eq('processing')
    end

    it 'returns ready when the preview is attached' do
      report_template.odt_template_file.attach(
        io: StringIO.new('odt'), filename: 'template.odt', content_type: 'application/vnd.oasis.opendocument.text'
      )
      report_template.odt_template_file_preview.attach(
        io: StringIO.new('pdf'), filename: 'template.pdf', content_type: 'application/pdf'
      )

      expect(report_template.preview_status).to eq('ready')
    end

    it 'returns not_previewable when the odt file is attached but not previewable' do
      report_template.odt_template_file.attach(
        io: StringIO.new('odt'), filename: 'template.odt', content_type: 'application/vnd.oasis.opendocument.text'
      )
      allow(ActiveStorageFileUtil).to receive(:previewable_document?).and_return(false)

      expect(report_template.preview_status).to eq('not_previewable')
    end

    it 'returns failed when the docx blob is marked as preview_failed' do
      report_template.docx_template_file.attach(
        io: StringIO.new('docx'), filename: 'template.docx',
        content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      )
      report_template.docx_template_file.blob.update_column(:metadata, { 'preview_failed' => true })

      expect(report_template.preview_status).to eq('failed')
    end

    it 'returns ready over failed when a preview exists despite an earlier failure flag' do
      report_template.docx_template_file.attach(
        io: StringIO.new('docx'), filename: 'template.docx',
        content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      )
      report_template.docx_template_file.blob.update_column(:metadata, { 'preview_failed' => true })
      report_template.odt_template_file_preview.attach(
        io: StringIO.new('pdf'), filename: 'template.pdf', content_type: 'application/pdf'
      )

      expect(report_template.preview_status).to eq('ready')
    end
  end
end
