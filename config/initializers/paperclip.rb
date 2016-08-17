
if ENV['PAPERCLIP_HASH_SECRET'].nil?
  puts "WARNING! Environment variable PAPERCLIP_HASH_SECRET must be set."
  exit 1
end

Paperclip::Attachment.default_options.merge!({
  hash_data: ':class/:attachment/:id/:style',
  hash_secret: ENV['PAPERCLIP_HASH_SECRET'],
  preserve_files: false,
  url: '/system/:class/:attachment/:id_partition/:hash/:style/:filename'
})

if ENV['PAPERCLIP_STORAGE'] == "s3"

  if ENV['S3_BUCKET'].nil? or ENV['AWS_REGION'].nil? or
    ENV['AWS_ACCESS_KEY_ID'].nil? or ENV['AWS_SECRET_ACCESS_KEY'].nil?
    puts "WARNING! Environment variables S3_BUCKET, AWS_REGION, " +
         "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set."
    exit 1
  end
  Paperclip::Attachment.default_options.merge!({
    url: ':s3_domain_url',
    path: '/:class/:attachment/:id_partition/:hash/:style/:filename',
    storage: :s3,
    s3_host_name: "s3.#{ENV['AWS_REGION']}.amazonaws.com",
    s3_protocol: 'https',
    s3_credentials: {
      bucket: ENV['S3_BUCKET'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    },
    s3_permissions: {
      original: :private,
      medium: :private
    },
    s3_storage_class: {
      medium: :reduced_redundancy,
      thumb: :reduced_redundancy,
      icon: :reduced_redundancy,
      icon_small: :reduced_redundancy
    }
  })
elsif ENV['PAPERCLIP_STORAGE'] == "filesystem"
  Paperclip::Attachment.default_options.merge!({
    storage: :filesystem
  })

end

Paperclip::Attachment.class_eval do
  def is_stored_on_s3?
    options[:storage].to_sym == :s3
  end

  def fetch
    Paperclip.io_adapters.for self
  end
end
