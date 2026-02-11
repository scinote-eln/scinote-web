# frozen_string_literal: true

require 'active_storage/service/s3_service'

module ActiveStorage
  class Service::CustomS3Service < Service::S3Service
    attr_reader :subfolder

    def initialize(bucket:, upload: {}, public: false, **options)
      @subfolder = options.delete(:subfolder)
      super
    end

    def delete_prefixed(prefix)
      prefix = File.join(subfolder, prefix) if subfolder.present?
      instrument :delete_prefixed, prefix: prefix do
        bucket.objects(prefix: prefix).batch_delete!
      end
    end

    private

    def upload_stream(key:, **options, &block)
      if @transfer_manager
        key = File.join(subfolder, key) if subfolder.present?
        @transfer_manager.upload_stream(key: key, bucket: bucket.name, **options, &block)
      else
        object_for(key).upload_stream(**options, &block)
      end
    end

    def object_for(key)
      key = File.join(subfolder, key) if subfolder.present?
      bucket.object(key)
    end
  end
end
