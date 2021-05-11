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
      prefix = subfolder.present? ? File.join(subfolder, prefix) : prefix
      instrument :delete_prefixed, prefix: prefix do
        bucket.objects(prefix: prefix).batch_delete!
      end
    end

    def path_for(key)
      subfolder.present? ? File.join(subfolder, key) : key
    end

    private

    def object_for(key)
      key = subfolder.present? ? File.join(subfolder, key) : key
      bucket.object(key)
    end
  end
end
