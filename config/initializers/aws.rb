# frozen_string_literal: true

if ENV['PAPERCLIP_STORAGE'] == 's3'
  S3_BUCKET = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])
end
