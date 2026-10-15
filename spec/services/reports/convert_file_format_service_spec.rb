# frozen_string_literal: true

require 'rails_helper'

describe Reports::ConvertFileFormatService do
  let(:dir) { Dir.mktmpdir }
  let(:source) { File.new(File.join(dir, 'report.docx'), 'w') }

  after do
    source.close
    FileUtils.remove_entry(dir)
  end

  # Stands in for LibreOffice: writes the converted files next to the originals
  def stub_libreoffice(success: true, create_output: true, ext: 'pdf')
    allow(described_class).to receive(:system) do |*args|
      if create_output
        args.select { |a| a.to_s.end_with?('.docx') }.each do |path|
          File.write(path.sub(/docx\z/, ext), 'converted')
        end
      end
      success
    end
  end

  describe '.run_libreoffice!' do
    it 'runs soffice headless with a timeout and the output directory' do
      expect(described_class).to receive(:system).with(
        'timeout', Constants::PREVIEW_TIMEOUT_SECONDS.to_s, 'soffice', '--headless', '--invisible',
        '--convert-to', 'pdf', '--outdir', '/out', '/in/a.docx', '/in/b.docx'
      ).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LIBREOFFICE_PATH').and_return(nil)
      expect(described_class.run_libreoffice!(['/in/a.docx', '/in/b.docx'], '/out', 'pdf')).to be(true)
    end

    it 'uses LIBREOFFICE_PATH when set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LIBREOFFICE_PATH').and_return('/opt/lo/soffice')
      expect(described_class).to receive(:system).with(
        'timeout', anything, '/opt/lo/soffice', '--headless', '--invisible', '--convert-to', 'pdf', '--outdir',
        '/out', '/in/a.docx'
      ).and_return(true)
      described_class.run_libreoffice!(['/in/a.docx'], '/out', 'pdf')
    end
  end

  describe '.convert' do
    it 'returns the converted file opened from the same directory' do
      stub_libreoffice
      result = described_class.convert(source, 'pdf')
      expect(File.basename(result.path)).to eq('report.pdf')
      expect(File.dirname(result.path)).to eq(File.dirname(source.path))
      expect(result.read).to eq('converted')
    ensure
      result&.close
    end

    it 'raises when LibreOffice fails' do
      stub_libreoffice(success: false)
      expect { described_class.convert(source, 'pdf') }
        .to raise_error(StandardError, /There was an error generating pdf for file #{Regexp.escape(source.path)}/)
    end

    it 'raises when no output file was produced' do
      stub_libreoffice(create_output: false)
      expect { described_class.convert(source, 'pdf') }.to raise_error(StandardError, /error generating pdf/)
    end
  end

  describe '.convert_batch' do
    let(:second) { File.new(File.join(dir, 'second.docx'), 'w') }

    after { second.close }

    it 'returns an empty list without files' do
      expect(described_class).not_to receive(:system)
      expect(described_class.convert_batch([], 'pdf')).to eq([])
    end

    it 'returns the paths of all converted files' do
      stub_libreoffice
      expect(described_class.convert_batch([source, second], 'pdf')).to eq(
        [File.join(dir, 'report.pdf'), File.join(dir, 'second.pdf')]
      )
    end

    it 'names the files that were not converted' do
      allow(described_class).to receive(:system) do |*args|
        File.write(args.find { |a| a.to_s.end_with?('report.docx') }.sub(/docx\z/, 'pdf'), 'x')
        true
      end
      expect { described_class.convert_batch([source, second], 'pdf') }
        .to raise_error(StandardError, "Failed to convert: #{File.join(dir, 'second.pdf')}")
    end

    it 'raises when LibreOffice reports a failure' do
      stub_libreoffice(success: false)
      expect { described_class.convert_batch([source, second], 'pdf') }.to raise_error(StandardError, /Failed/)
    end
  end
end
