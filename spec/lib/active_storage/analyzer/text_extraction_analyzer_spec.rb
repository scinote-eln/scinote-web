# frozen_string_literal: true

require 'rails_helper'

describe ActiveStorage::Analyzer::TextExtractionAnalyzer do
  let(:asset) { create(:asset) }
  let(:blob) { asset.file.blob }
  let(:analyzer) { described_class.new(blob) }

  def popen_result(text)
    instance_double(IO, read: text)
  end

  def vector_for(asset)
    AssetTextDatum.connection.select_value(
      "SELECT data_vector::text FROM asset_text_data WHERE asset_id = #{asset.id.to_i}"
    )
  end

  describe '.accept?' do
    it 'accepts small extractable files attached to an asset' do
      blob.update!(content_type: 'application/pdf')
      expect(described_class.accept?(blob)).to be true
    end

    it 'rejects unsupported content types' do
      expect(blob.content_type).to eq 'image/jpeg'
      expect(described_class.accept?(blob)).to be false
    end

    it 'rejects files that are too large' do
      blob.update!(content_type: 'text/plain', byte_size: Constants::TEXT_EXTRACT_MAX_FILE_SIZE + 1)
      expect(described_class.accept?(blob)).to be false
    end

    it 'rejects blobs that are not attached to an asset' do
      orphan = ActiveStorage::Blob.create_before_direct_upload!(
        filename: 'a.txt', byte_size: 10, checksum: 'x', content_type: 'text/plain'
      )
      expect(described_class.accept?(orphan)).to be false
    end
  end

  describe '.analyze_later?' do
    it 'is true' do
      expect(described_class.analyze_later?).to be true
    end
  end

  describe '#metadata' do
    around do |example|
      old = ENV['TIKA_PATH']
      example.run
    ensure
      ENV['TIKA_PATH'] = old
    end

    context 'with a PDF' do
      before { blob.update!(content_type: 'application/pdf') }

      it 'extracts text with pdftotext and stores a text vector' do
        expect(IO).to receive(:popen).with(['pdftotext', kind_of(String), '-'], 'r')
                                     .and_return(popen_result('hello world'))

        expect(analyzer.metadata).to eq(text_extracted: true)
        expect(asset.reload.asset_text_datum).to be_present
        expect(vector_for(asset)).to include('hello', 'world')
      end

      it 'falls back to tika when pdftotext is not installed' do
        ENV['TIKA_PATH'] = '/opt/tika.jar'
        allow(IO).to receive(:popen).with(['pdftotext', kind_of(String), '-'], 'r').and_raise(Errno::ENOENT)
        expect(IO).to receive(:popen)
          .with(['java', '-Djava.awt.headless=true', '-jar', '/opt/tika.jar', '-t', kind_of(String)], 'r')
          .and_return(popen_result('fallback text'))

        expect(analyzer.metadata).to eq(text_extracted: true)
        expect(vector_for(asset)).to include('fallback')
      end
    end

    context 'with another document type' do
      before { blob.update!(content_type: 'text/plain') }

      it 'uses the default tika path when TIKA_PATH is unset' do
        ENV.delete('TIKA_PATH')
        expect(IO).to receive(:popen)
          .with(['java', '-Djava.awt.headless=true', '-jar', 'tika-app.jar', '-t', kind_of(String)], 'r')
          .and_return(popen_result('plain words'))

        expect(analyzer.metadata).to eq(text_extracted: true)
        expect(vector_for(asset)).to include('plain', 'word')
      end

      it 'uses TIKA_PATH when set' do
        ENV['TIKA_PATH'] = '/custom/tika.jar'
        expect(IO).to receive(:popen)
          .with(['java', '-Djava.awt.headless=true', '-jar', '/custom/tika.jar', '-t', kind_of(String)], 'r')
          .and_return(popen_result('x'))
        analyzer.metadata
      end

      it 'stores an empty vector for empty tika output and reuses the existing text datum' do
        create(:asset_text_datum, asset: asset)
        allow(IO).to receive(:popen).and_return(popen_result(''))

        expect { analyzer.metadata }.not_to(change { AssetTextDatum.where(asset_id: asset.id).count })
        expect(vector_for(asset)).to eq('')
      end

      it 'logs and carries on when the text datum is invalid' do
        allow(IO).to receive(:popen).and_return(popen_result('x'))
        # the Asset is loaded from the attachment inside the analyzer
        allow_any_instance_of(Asset).to receive(:create_asset_text_datum!)
          .and_raise(ActiveRecord::RecordInvalid.new(AssetTextDatum.new))
        allow(Rails.logger).to receive(:error)

        expect(analyzer.metadata).to eq(text_extracted: true)
        expect(Rails.logger).to have_received(:error).with(/Asset #{asset.id}: file text unsuccessfully extracted/)
      end
    end

    context 'with a MarvinJS asset' do
      let(:xml) { '<cml xmlns="x"><Field name="text">benzene</Field><Field name="text">ring</Field></cml>' }

      before { blob.update!(content_type: 'text/plain', metadata: blob.metadata.merge(asset_type: 'marvinjs', description: xml)) }

      pending 'bug: lib/active_storage/analyzer/text_extraction_analyzer.rb:40 reads description from the Tempfile ' \
              '(file.metadata) instead of the blob, so MarvinJS text extraction raises NoMethodError' do
        expect(analyzer.metadata).to eq(text_extracted: true)
        expect(vector_for(asset)).to include('benzene', 'ring')
      end
    end
  end
end
