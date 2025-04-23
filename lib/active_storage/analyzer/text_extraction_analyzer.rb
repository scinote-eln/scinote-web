# frozen_string_literal: true

module ActiveStorage
  class Analyzer::TextExtractionAnalyzer < Analyzer
    DEFAULT_TIKA_PATH = 'tika-app.jar'

    def self.accept?(blob)
      blob.content_type.in?(Constants::TEXT_EXTRACT_FILE_TYPES) &&
        blob.byte_size <= Constants::TEXT_EXTRACT_MAX_FILE_SIZE &&
        blob.attachments.where(record_type: 'Asset').any?
    end

    def self.analyze_later?
      true
    end

    def metadata
      download_blob_to_tempfile do |file|
        if blob.content_type == 'application/pdf'
          process_pdf(file)
        elsif blob.metadata[:asset_type] == 'marvinjs'
          process_marvinjs(file)
        else
          process_other(file)
        end
      end
    end

    private

    def process_pdf(file)
      text_data = IO.popen(['pdftotext', file.path, '-'], 'r').read
      create_or_update_text_data(text_data)
    rescue Errno::ENOENT
      logger.info "pdftotext isn't installed, falling back to default text extraction method"
      process_other(file)
    end

    def process_marvinjs(file)
      mjs_doc = Nokogiri::XML(file.metadata[:description])
      mjs_doc.remove_namespaces!
      text_data = mjs_doc.search("//Field[@name='text']").collect(&:text).join(' ')
      create_or_update_text_data(text_data)
    end

    def process_other(file)
      tika_path = ENV['TIKA_PATH'] || DEFAULT_TIKA_PATH
      text_data = IO.popen(['java', '-Djava.awt.headless=true', '-jar', tika_path, '-t', file.path], 'r').read
      create_or_update_text_data(text_data)
    end

    def create_or_update_text_data(text_data)
      @blob.attachments.where(record_type: 'Asset').each do |attachemnt|
        asset = attachemnt.record
        asset.create_asset_text_datum! if asset.asset_text_datum.blank?
        sql = ActiveRecord::Base.sanitize_sql_array(
          [
            'UPDATE "asset_text_data" SET "data_vector" = to_tsvector(:text_data) WHERE "id" = :id',
            { text_data: text_data, id: asset.asset_text_datum.id }
          ]
        )

        AssetTextDatum.connection.execute(sql)
        asset.update_estimated_size

        Rails.logger.info "Asset #{asset.id}: file text successfully extracted"
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Asset #{asset.id}: file text unsuccessfully extracted with error #{e.message}"
      end

      { text_extracted: true }
    end
  end
end
