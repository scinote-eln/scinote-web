# frozen_string_literal: true

namespace :active_storage do
  ID_PARTITION_LIMIT = 1_000_000_000
  DIGEST = OpenSSL::Digest.const_get('SHA1').new

  desc 'Copy all files from Paperclip to ActiveStorage, only same storage types'
  task :migrate_files, [:before] => :environment do |_, _args|
    if ENV['PAPERCLIP_STORAGE'] == 'filesystem' || ENV['ACTIVESTORAGE_SERVICE'] == 'local'
      ActiveStorage::Blob.find_each do |blob|
        src_path = Rails.root.join('public', 'system', blob.key)

        next unless src_path.exist?

        blob.transaction do
          blob.key = ActiveStorage::Blob.generate_unique_secure_token
          dst_path = ActiveStorage::Blob.service.path_for(blob.key)

          puts "Moving #{src_path} to #{dst_path}"
          FileUtils.mkdir_p(File.dirname(dst_path))
          FileUtils.mv(src_path, dst_path)
          blob.save!
        end
      end
      puts 'Finished'
    elsif ENV['PAPERCLIP_STORAGE'] == 's3' || ENV['ACTIVESTORAGE_SERVICE'] == 'amazon'
      S3_BUCKET = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])

      ActiveStorage::Blob.find_each do |blob|
        next unless blob.key.match?(%r{assets|experiments|temp_files|tiny_mce_assets|users|zip_exports\/})

        src_path = ENV['S3_SUBFOLDER'] ? File.join(ENV['S3_SUBFOLDER'], blob.key) : blob.key
        src_obj = S3_BUCKET.object(src_path)

        next unless src_obj.exists?

        blob.transaction do
          blob.key = ActiveStorage::Blob.generate_unique_secure_token
          dst_path = ENV['S3_SUBFOLDER'] ? File.join(ENV['S3_SUBFOLDER'], blob.key) : blob.key

          puts "Moving #{src_path} to #{dst_path}"

          src_obj.move_to(bucket: S3_BUCKET.name, key: dst_path)
          blob.save!
        end
      rescue StandardError => e
        puts 'Caught exception copying object ' + src_path + ':'
        puts e.message
      end
      puts 'Finished'
    end
  end
end
