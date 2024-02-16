# frozen_string_literal: true

module ActiveStorage
  class Analyzer::TextExtractionAnalyzer < Analyzer
    def self.accept?(blob)
      blob.content_type.in?(Constants::TEXT_EXTRACT_FILE_TYPES) && blob.attachments.where(record_type: 'Asset').any?
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
      text_data = Yomu.new(file.path).text
      create_or_update_text_data(text_data)
    end

    def create_or_update_text_data(text_data)
      @blob.attachments.where(record_type: 'Asset').each do |attachemnt|
        asset = attachemnt.record
        if asset.asset_text_datum.present?
          # Update existing text datum if it exists
          asset.asset_text_datum.update!(data: text_data)
        else
          # Create new text datum
          asset.create_asset_text_datum!(data: text_data)
        end

        asset.update_estimated_size

        Rails.logger.info "Asset #{asset.id}: file text successfully extracted"
      end

      { text_extracted: true }
    end
  end
end
