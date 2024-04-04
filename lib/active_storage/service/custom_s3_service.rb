# frozen_string_literal: true

require 'active_storage/custom_errors'
require 'active_storage/service/s3_service'

module ActiveStorage
  class Service::CustomS3Service < Service::S3Service
    STAGING_TAG_KEY = 'State'
    STAGING_TAG_VALUE = 'Staging'

    attr_reader :subfolder, :staging_bucket

    def initialize(bucket:, upload: {}, public: false, **options)
      @subfolder = options.delete(:subfolder)
      staging_bucket = options.delete(:staging_bucket)
      super
      @staging_bucket = @client.bucket(staging_bucket) if staging_bucket.present?
    end

    def download(key, &block)
      return super unless staging_bucket

      if bucket.client
               .get_object_tagging(bucket: bucket.name, key: subfolder.present? ? File.join(subfolder, key) : key)
               .tag_set.find { |tag| tag.key == STAGING_TAG_KEY && tag.value == STAGING_TAG_VALUE }
        raise FileNotReadyError
      end

      super
    rescue Aws::S3::Errors::NoSuchKey
      raise ActiveStorage::FileNotFoundError
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
      instrument :url, key: do |payload|
        generated_url =
          object_for_upload(key).presigned_url(:put, expires_in: expires_in.to_i,
                                               content_type:, content_length:, content_md5: checksum,
                                               metadata: custom_metadata, whitelist_headers: %w(content-length),
                                               **upload_options)

        payload[:url] = generated_url

        generated_url
      end
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

    def upload_with_single_part(key, io, checksum: nil, content_type: nil, content_disposition: nil, custom_metadata: {})
      object_for_upload(key)
        .put(body: io, content_md5: checksum, content_type:,
             content_disposition:, metadata: custom_metadata, **upload_options)
    rescue Aws::S3::Errors::BadDigest
      raise ActiveStorage::IntegrityError
    end

    def upload_with_multipart(key, io, content_type: nil, content_disposition: nil, custom_metadata: {})
      part_size = [io.size.fdiv(MAXIMUM_UPLOAD_PARTS_COUNT).ceil, MINIMUM_UPLOAD_PART_SIZE].max

      object_for_upload(key)
        .upload_stream(content_type:, content_disposition:, part_size:,
                       metadata: custom_metadata, **upload_options) do |out|
        IO.copy_stream(io, out)
      end
    end

    def object_for(key)
      key = subfolder.present? ? File.join(subfolder, key) : key
      bucket.object(key)
    end

    def object_for_upload(key)
      key = subfolder.present? ? File.join(subfolder, key) : key
      if staging_bucket
        # Create an empty stub file in the main bucket, size of 4KB is needed for ActiveStorage::Blob::Identifiable
        bucket.object(key).put(body: StringIO.new(' ' * 4.kilobytes),
                               tagging: "#{STAGING_TAG_KEY}=#{STAGING_TAG_VALUE}")
        staging_bucket.object(key)
      else
        bucket.object(key)
      end
    end
  end
end
