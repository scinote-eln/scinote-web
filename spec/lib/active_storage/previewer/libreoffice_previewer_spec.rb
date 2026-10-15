# frozen_string_literal: true

require 'rails_helper'

describe ActiveStorage::Previewer::LibreofficePreviewer do
  def blob_double(content_type: 'application/pdf', byte_size: 100, filename: 'report.docx')
    instance_double(
      ActiveStorage::Blob,
      content_type: content_type, byte_size: byte_size, id: 42,
      filename: ActiveStorage::Filename.new(filename)
    )
  end

  describe '.accept?' do
    it 'accepts previewable office documents' do
      expect(described_class.accept?(blob_double(content_type: 'application/msword'))).to be true
    end

    # ActiveStorage::Filename#extension has no leading dot, but ActiveStorageFileUtil compares against '.xlsx'
    pending 'bug: app/utilities/active_storage_file_util.rb:11 compares Filename#extension (no dot) with dotted extensions' do
      expect(described_class.accept?(blob_double(content_type: 'application/zip', filename: 'a.xlsx'))).to be true
    end

    it 'rejects other files' do
      expect(described_class.accept?(blob_double(content_type: 'image/png', filename: 'a.png'))).to be false
    end

    it 'rejects too large and missing blobs' do
      big = blob_double(content_type: 'application/msword', byte_size: Constants::PREVIEW_MAX_FILE_SIZE + 1)
      expect(described_class.accept?(big)).to be false
      expect(described_class.accept?(nil)).to be false
    end
  end

  describe '#preview' do
    let(:blob) { blob_double }
    let(:previewer) { described_class.new(blob) }
    let(:workdir) { Dir.mktmpdir }
    let(:input) { File.join(workdir, 'input.docx').tap { |p| File.write(p, 'doc') } }

    before do
      allow(blob).to receive(:open) do |**_opts, &block|
        File.open(input) { |f| block.call(f) }
      end
    end

    after { FileUtils.remove_entry(workdir) }

    around do |example|
      old = ENV['LIBREOFFICE_PATH']
      example.run
    ensure
      ENV['LIBREOFFICE_PATH'] = old
    end

    it 'converts with a timeout wrapped soffice call, yields the png and removes it afterwards' do
      ENV['LIBREOFFICE_PATH'] = '/opt/soffice'
      expect(previewer).to receive(:system).with(
        'timeout', Constants::PREVIEW_TIMEOUT_SECONDS.to_s, '/opt/soffice',
        '--headless', '--invisible', '--convert-to', 'png', '--outdir', workdir, input
      ) do
        File.write(File.join(workdir, 'input.png'), 'PNGDATA')
        true
      end

      yielded = nil
      previewer.preview do |attrs|
        yielded = attrs.merge(content: attrs[:io].read)
        attrs[:io].close
      end

      expect(yielded).to include(filename: 'report.png', content_type: 'image/png', content: 'PNGDATA')
      expect(File).not_to exist(File.join(workdir, 'input.png'))
    end

    it 'defaults to soffice' do
      ENV.delete('LIBREOFFICE_PATH')
      expect(previewer).to receive(:system).with('timeout', anything, 'soffice', *Array.new(6) { anything }, input)
                                           .and_return(false)
      expect { previewer.preview { nil } }.to raise_error(StandardError)
    end

    it 'raises when the conversion fails' do
      allow(previewer).to receive(:system).and_return(false)
      expect { previewer.preview { raise 'must not yield' } }
        .to raise_error(StandardError, 'There was an error generating document preview, blob id: 42')
    end

    it 'raises when the conversion succeeds without producing a file' do
      allow(previewer).to receive(:system).and_return(true)
      expect { previewer.preview { raise 'must not yield' } }
        .to raise_error(StandardError, /error generating document preview/)
    end

    it 'removes the generated png even if the consumer raises' do
      allow(previewer).to receive(:system) do
        File.write(File.join(workdir, 'input.png'), 'x')
        true
      end
      expect { previewer.preview { |a| a[:io].close; raise 'boom' } }.to raise_error('boom')
      expect(File).not_to exist(File.join(workdir, 'input.png'))
    end
  end
end
