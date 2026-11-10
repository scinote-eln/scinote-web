# frozen_string_literal: true

require 'rails_helper'

describe ReportTemplates::ConvertOdtToDocxJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:report_template) { ReportTemplate.create!(subject: project) }
  let(:converted_path) { Rails.root.join('tmp', "convert_odt_to_docx_spec_#{SecureRandom.hex(4)}.docx") }

  before do
    report_template.odt_template_file.attach(io: StringIO.new('odt source'), filename: 'my_template.odt')
    File.binwrite(converted_path, 'docx result')
  end

  after { FileUtils.rm_f(converted_path) }

  it 'converts the odt template to docx and attaches it with the base file name' do
    opened = nil
    expect(Reports::ConvertFileFormatService).to receive(:convert) do |file, format|
      opened = [File.binread(file.path), format]
      File.open(converted_path)
    end

    described_class.perform_now(report_template.id)

    expect(opened).to eq ['odt source', 'docx']
    report_template.reload
    expect(report_template.docx_template_file).to be_attached
    expect(report_template.docx_template_file.filename.to_s).to eq 'my_template.docx'
    expect(report_template.docx_template_file.download).to eq 'docx result'
  end

  it 'leaves the template without docx when the conversion fails' do
    allow(Reports::ConvertFileFormatService).to receive(:convert).and_raise(StandardError, 'conversion failed')

    expect { described_class.perform_now(report_template.id) }.to raise_error(StandardError, 'conversion failed')

    expect(report_template.reload.docx_template_file).not_to be_attached
  end
end
