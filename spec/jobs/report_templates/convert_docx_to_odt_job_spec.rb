# frozen_string_literal: true

require 'rails_helper'

describe ReportTemplates::ConvertDocxToOdtJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:report_template) { ReportTemplate.create!(subject: project) }
  let(:converted_path) { Rails.root.join('tmp', "convert_docx_to_odt_spec_#{SecureRandom.hex(4)}.odt") }

  before do
    report_template.docx_template_file.attach(io: StringIO.new('docx source'), filename: 'my_template.docx')
    File.binwrite(converted_path, 'odt result')
    allow(ReportTemplate).to receive(:find).and_call_original
  end

  after { FileUtils.rm_f(converted_path) }

  it 'converts the docx template to odt, attaches it and schedules the preview' do
    opened = nil
    expect(Reports::ConvertFileFormatService).to receive(:convert) do |file, format|
      opened = [File.binread(file.path), format]
      File.open(converted_path)
    end
    expect(ReportTemplates::ReportTemplatePreviewJob).to receive(:perform_later).with(report_template.id)

    described_class.perform_now(report_template.id)

    expect(opened).to eq ['docx source', 'odt']
    report_template.reload
    expect(report_template.odt_template_file).to be_attached
    expect(report_template.odt_template_file.filename.to_s).to eq 'my_template.odt'
    expect(report_template.odt_template_file.content_type).to eq 'application/vnd.oasis.opendocument.text'
    expect(report_template.odt_template_file.download).to eq 'odt result'
  end

  it 'does not attach anything or build a preview when the conversion fails' do
    allow(Reports::ConvertFileFormatService).to receive(:convert).and_raise(StandardError, 'conversion failed')
    expect(ReportTemplates::ReportTemplatePreviewJob).not_to receive(:perform_later)

    expect { described_class.perform_now(report_template.id) }.to raise_error(StandardError, 'conversion failed')

    expect(report_template.reload.odt_template_file).not_to be_attached
  end

  it 'raises RecordNotFound for an unknown template' do
    expect { described_class.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
