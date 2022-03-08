# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
require 'active_storage/service/s3_service'

module ActiveStorage
  class Service::CustomS3Service < Service::S3Service
    attr_reader :subfolder

    def initialize(bucket:, upload: {}, public: false, **options)
      @subfolder = options.delete(:subfolder)
      super
=======
# Copyright (c) 2017-2019 David Heinemeier Hansson, Basecamp
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'aws-sdk-s3'
require 'active_support/core_ext/numeric/bytes'
=======
require 'active_storage/service/s3_service'
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.

module ActiveStorage
  class Service::CustomS3Service < Service::S3Service
    attr_reader :subfolder

    def initialize(bucket:, upload: {}, public: false, **options)
      @subfolder = options.delete(:subfolder)
<<<<<<< HEAD

      @client = Aws::S3::Resource.new(**options)
      @bucket = @client.bucket(bucket)

      @upload_options = upload
    end

    def upload(key, io, checksum: nil, content_type: nil, **)
      instrument :upload, key: key, checksum: checksum do
        object_for(key).put(upload_options.merge(body: io, content_md5: checksum, content_type: content_type))
      rescue Aws::S3::Errors::BadDigest
        raise ActiveStorage::IntegrityError
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          stream(key, &block)
        end
      else
        instrument :download, key: key do
          object_for(key).get.body.string.force_encoding(Encoding::BINARY)
        rescue Aws::S3::Errors::NoSuchKey
          raise ActiveStorage::FileNotFoundError
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        object_for(key).get(range: "bytes=#{range.begin}-#{range.exclude_end? ? range.end - 1 : range.end}")
                       .body
                       .read
                       .force_encoding(Encoding::BINARY)
      rescue Aws::S3::Errors::NoSuchKey
        raise ActiveStorage::FileNotFoundError
      end
    end

    def delete(key)
      instrument :delete, key: key do
        object_for(key).delete
      end
>>>>>>> Initial commit of 1.17.2 merge
=======
      super
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end

    def delete_prefixed(prefix)
      prefix = subfolder.present? ? File.join(subfolder, prefix) : prefix
      instrument :delete_prefixed, prefix: prefix do
        bucket.objects(prefix: prefix).batch_delete!
      end
    end

<<<<<<< HEAD
<<<<<<< HEAD
=======
    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = object_for(key).exists?
        payload[:exist] = answer
        answer
      end
    end

    def url(key, expires_in:, filename:, disposition:, content_type:)
      instrument :url, key: key do |payload|
        generated_url = object_for(key).presigned_url :get, expires_in: expires_in.to_i,
          response_content_disposition: content_disposition_with(type: disposition, filename: filename),
          response_content_type: content_type

        payload[:url] = generated_url

        generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        generated_url = object_for(key).presigned_url :put, expires_in: expires_in.to_i,
          content_type: content_type, content_length: content_length, content_md5: checksum,
          whitelist_headers: ['content-length']

        payload[:url] = generated_url

        generated_url
      end
    end

    def headers_for_direct_upload(_, content_type:, checksum:, **)
      { 'Content-Type' => content_type, 'Content-MD5' => checksum }
    end

>>>>>>> Initial commit of 1.17.2 merge
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    def path_for(key)
      subfolder.present? ? File.join(subfolder, key) : key
    end

    private

    def object_for(key)
      key = subfolder.present? ? File.join(subfolder, key) : key
      bucket.object(key)
    end
<<<<<<< HEAD
<<<<<<< HEAD
=======

    # Reads the object for the given key in chunks, yielding each to the block.
    def stream(key)
      object = object_for(key)

      chunk_size = 5.megabytes
      offset = 0

      raise ActiveStorage::FileNotFoundError unless object.exists?

      while offset < object.content_length
        yield object.get(range: "bytes=#{offset}-#{offset + chunk_size - 1}").body.read.force_encoding(Encoding::BINARY)
        offset += chunk_size
      end
    end
>>>>>>> Initial commit of 1.17.2 merge
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
  end
end
