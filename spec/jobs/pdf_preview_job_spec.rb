# frozen_string_literal: true

require 'rails_helper'

describe PdfPreviewJob, type: :job do
  let(:team) { create :team }
  let(:asset) { create :asset, team: team }
  let(:service) { instance_double(PdfPreviewService, generate!: true) }

  before do
    asset.file.attach(io: StringIO.new('docx'), filename: 'doc.docx')
    asset.update_column(:pdf_preview_processing, true)
  end

  it 'generates the preview for the asset file into file_pdf_preview and clears the processing flag' do
    expect(PdfPreviewService).to receive(:new) do |blob, attached|
      expect(blob).to eq asset.file.blob
      expect(attached.name).to eq 'file_pdf_preview'
      expect(attached.record).to eq asset
      service
    end

    described_class.perform_now(asset.id)

    expect(service).to have_received(:generate!)
    expect(asset.reload.pdf_preview_processing).to be false
  end

  context 'when the preview generation fails' do
    before do
      allow(PdfPreviewService).to receive(:new).and_return(service)
      allow(service).to receive(:generate!).and_raise(StandardError, 'soffice crashed')
      allow(Rails.logger).to receive(:error)
    end

    it 'discards the job, flags the blob as failed and clears the processing flag' do
      expect { described_class.perform_now(asset.id) }.not_to raise_error

      asset.reload
      expect(asset.pdf_preview_processing).to be false
      expect(asset.file.blob.metadata['preview_failed']).to be true
      expect(Rails.logger).to have_received(:error)
        .with(/Couldn't generate PDF preview for Asset with id: #{asset.id}.*soffice crashed/m)
    end
  end

  it 'discards the job quietly when the asset does not exist' do
    expect(PdfPreviewService).not_to receive(:new)
    allow(Rails.logger).to receive(:error)

    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
