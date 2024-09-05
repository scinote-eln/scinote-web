# frozen_string_literal: true

require 'httparty'
require 'active_storage/service/s3_service'

template_zip_url_string = ENV.fetch('REPORT_TEMPLATES_ZIP_URL', nil)

return unless template_zip_url_string.present?

template_zip_url = URI.parse(template_zip_url_string)
contents = case template_zip_url.scheme
           when 'https'
             HTTParty.get(template_zip_url).body
           when 's3'
             ActiveStorage::Service::S3Service.new(
               bucket: template_zip_url.host
             ).download(template_zip_url.path[1..])
           end

root_folder = nil
Zip::File.open_buffer(StringIO.new(contents)) do |zip|
  zip.each do |entry|
    # set root zip folder
    root_folder = entry.name and next if entry.name.count('/') == 1

    # create path while omitting root zip folder
    path = Rails.root.join('app', 'views', 'reports', entry.name.sub(root_folder, ''))
    path.dirname.mkpath

    # don't try and write file if entry is a folder
    next if entry.name.ends_with?('/')

    path.open('wb') do |f|
      f.write(entry.get_input_stream.read)
    end
  end
end
