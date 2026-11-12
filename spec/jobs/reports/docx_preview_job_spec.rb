# frozen_string_literal: true

require 'rails_helper'

describe Reports::DocxPreviewJob, type: :job do
  let(:report) { create :report }
  let(:service) { instance_double(PdfPreviewService, generate!: true) }

  before do
    report.docx_file.attach(io: StringIO.new('docx'), filename: 'report.docx')
  end

  it 'generates the pdf preview of the docx file into docx_preview_file' do
    expect(PdfPreviewService).to receive(:new) do |blob, attached|
      expect(blob).to eq report.docx_file.blob
      expect(attached.name).to eq 'docx_preview_file'
      expect(attached.record).to eq report
      service
    end

    described_class.perform_now(report.id)

    expect(service).to have_received(:generate!)
  end

  it 'discards the job and logs the error when the preview cannot be generated' do
    allow(PdfPreviewService).to receive(:new).and_return(service)
    allow(service).to receive(:generate!).and_raise(StandardError, 'libreoffice failed')
    allow(Rails.logger).to receive(:error)

    expect { described_class.perform_now(report.id) }.not_to raise_error

    expect(Rails.logger).to have_received(:error)
      .with(/Couldn't generate PDF preview for DOCX Report with id: #{report.id}.*libreoffice failed/m)
  end

  it 'discards the job when the report does not exist' do
    expect(PdfPreviewService).not_to receive(:new)

    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
