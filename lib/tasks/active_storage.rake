# frozen_string_literal: true

namespace :active_storage do
  ID_PARTITION_LIMIT = 1_000_000_000
  DIGEST = OpenSSL::Digest.const_get('SHA1').new

  def id_partition(id)
    if id < ID_PARTITION_LIMIT
      format('%09d', id).scan(/\d{3}/).join('/')
    else
      format('%012d', id).scan(/\d{3}/).join('/')
    end
  end

  def hash_data(attachment)
    "#{attachment.record_type.underscore.pluralize}/#{attachment.name.pluralize}/#{attachment.record.id}/original"
  end

  def interpolate(pattern, attachment)
    path = pattern
    path = path.gsub(':class', attachment.record_type.underscore.pluralize)
    path = path.gsub(':attachment', attachment.name.pluralize)
    path = path.gsub(':id_partition', id_partition(attachment.record.id))
    path = path.gsub(':hash', OpenSSL::HMAC.hexdigest(DIGEST, ENV['PAPERCLIP_HASH_SECRET'], hash_data(attachment)))
    path.gsub(':filename', attachment.blob.filename.to_s)
  end

  desc 'Copy all files from Paperclip to ActiveStorage'
  task :migrate_files, [:before] => :environment do |_, _args|
    if ENV['PAPERCLIP_STORAGE'] == 'filesystem'
      local_path = "#{Rails.root}/public/system/:class/:attachment/:id_partition/:hash/original/:filename"

      ActiveStorage::Attachment.find_each do |attachment|
        src = interpolate(local_path, attachment)
        dst_dir = File.join(
          'storage',
          attachment.blob.key.first(2),
          attachment.blob.key.first(4).last(2)
        )
        dst = File.join(dst_dir, attachment.blob.key)

        FileUtils.mkdir_p(dst_dir)
        puts "Copying #{src} to #{dst}"
        FileUtils.cp(src, dst)
      end
    elsif ENV['PAPERCLIP_STORAGE'] == 's3'

      s3_path = ':class/:attachment/:id_partition/:hash/original/:filename'
      s3_path = "#{ENV['S3_SUBFOLDER']}/" + s3_path if ENV['S3_SUBFOLDER']

      ActiveStorage::Attachment.find_each do |attachment|
        src_path = interpolate(s3_path, attachment)

        next unless S3_BUCKET.object(src_path).exists?

        dst_path = ENV['S3_SUBFOLDER'] ? File.join(ENV['S3_SUBFOLDER'], attachment.blob.key) : attachment.blob.key

        puts "Copying #{src_path} to #{dst_path}"

        s3.copy_object(bucket: S3_BUCKET.name,
                       copy_source: S3_BUCKET.name + src_path,
                       key: dst_path)
      rescue StandardError => e
        puts 'Caught exception copying object ' + src_path + ':'
        puts e.message
      end
    end
  end
end
