# frozen_string_literal: true

require 'fileutils'

module ModelExporters
  class ModelExporter
    def copy_files(assets, attachment_name, dir_name)
      assets.flatten.each do |a|
        next unless a.public_send(attachment_name).present?

        unless a.public_send(attachment_name).exists?
          raise StandardError,
                "File id:#{a.id} of type #{attachment_name} is missing"
        end
        yield if block_given?
        dir = FileUtils.mkdir_p(File.join(dir_name, a.id.to_s)).first
        if defined?(S3_BUCKET)
          s3_asset =
            S3_BUCKET.object(a.public_send(attachment_name).path.remove(%r{^/}))
          file_name = a.public_send(attachment_name).original_filename
          File.open(File.join(dir, file_name), 'wb') do |f|
            s3_asset.get(response_target: f)
          end
        else
          FileUtils.cp(
            a.public_send(attachment_name).path,
            File.join(dir, a.public_send(attachment_name).original_filename)
          )
        end
      end
    end

    def export_to_dir
      raise NotImplementedError, '#export_to_dir method not implemented.'
    end
  end
end
