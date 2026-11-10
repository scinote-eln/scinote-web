# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfPreviewService do
  let(:report) { create :report }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new('docx bytes'), filename: 'My Doc.docx',
                                           content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
  end
  let(:service) { described_class.new(blob, report.pdf_file) }

  describe '#generate!' do
    it 'converts the blob with LibreOffice and attaches the resulting pdf named after the blob' do
      produced = nil
      allow(service).to receive(:system) do |*args|
        expect(args.first(2)).to eq ['timeout', Constants::PREVIEW_TIMEOUT_SECONDS.to_s]
        expect(args[3..6]).to eq %w(--headless --invisible --convert-to pdf)
        expect(args[2]).to eq(ENV['LIBREOFFICE_PATH'] || 'soffice')
        outdir = args[args.index('--outdir') + 1]
        input = args.last
        expect(File.read(input)).to eq 'docx bytes'
        produced = File.join(outdir, "#{File.basename(input, '.*')}.pdf")
        File.write(produced, 'pdf bytes')
        true
      end

      service.generate!

      expect(report.reload.pdf_file).to be_attached
      expect(report.pdf_file.filename.to_s).to eq 'My Doc.pdf'
      expect(report.pdf_file.download).to eq 'pdf bytes'
      expect(File.exist?(produced)).to be false
    end

    it 'raises and attaches nothing when LibreOffice fails' do
      allow(service).to receive(:system).and_return(false)

      expect { service.generate! }.to raise_error(StandardError, "There was an error generating PDF preview, blob id: #{blob.id}")
      expect(report.reload.pdf_file).not_to be_attached
    end

    it 'raises when LibreOffice reports success but produced no file' do
      allow(service).to receive(:system).and_return(true)

      expect { service.generate! }.to raise_error(StandardError, /error generating PDF preview/)
      expect(report.reload.pdf_file).not_to be_attached
    end

    it 'uses LIBREOFFICE_PATH when it is set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LIBREOFFICE_PATH').and_return('/opt/lo/soffice')
      expect(service).to receive(:system).with('timeout', anything, '/opt/lo/soffice', any_args).and_return(false)

      expect { service.generate! }.to raise_error(StandardError)
    end
  end
end
