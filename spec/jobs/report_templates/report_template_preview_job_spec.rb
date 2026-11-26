# frozen_string_literal: true

require 'rails_helper'

describe ReportTemplates::ReportTemplatePreviewJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:report_template) { ReportTemplate.create!(subject: project) }
  let(:service) { instance_double(PdfPreviewService, generate!: true) }

  before { report_template.odt_template_file.attach(io: StringIO.new('odt'), filename: 'template.odt') }

  it 'generates the preview of the odt template into odt_template_file_preview' do
    expect(PdfPreviewService).to receive(:new) do |source, attached|
      # the job passes the ActiveStorage::Attached::One proxies, so source.id is the id of the ATTACHMENT row;
      # compare the blobs (attachment and blob ids only match while both sequences happen to be in sync)
      expect(source.name).to eq 'odt_template_file'
      expect(source.blob).to eq ReportTemplate.find(report_template.id).odt_template_file.blob
      expect(attached.name).to eq 'odt_template_file_preview'
      expect(attached.record).to eq report_template
      service
    end

    described_class.perform_now(report_template.id)

    expect(service).to have_received(:generate!)
  end

  it 'raises RecordNotFound for an unknown template' do
    expect { described_class.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
