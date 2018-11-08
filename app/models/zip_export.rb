# frozen_string_literal: true

require 'zip'
require 'fileutils'
require 'csv'

# To use ZipExport you have to define the generate_( type )_zip method!
# Example:
#   def generate_(type)_zip(tmp_dir, data, options = {})
#     attributes = options.fetch(:attributes) { :attributes_missing }
#     file = FileUtils.touch("#{tmp_dir}/export.csv").first
#     records = data
#     CSV.open(file, 'wb') do |csv|
#       csv << attributes
#       records.find_each do |entity|
#         csv << entity.values_at(*attributes.map(&:to_sym))
#       end
#     end
#   end

class ZipExport < ApplicationRecord
  belongs_to :user, optional: true
  has_attached_file :zip_file
  validates_attachment :zip_file,
                       content_type: { content_type: 'application/zip' }

  # When using S3 file upload, we can limit file accessibility with url signing
  def presigned_url(style = :original,
                    download: false,
                    timeout: Constants::URL_SHORT_EXPIRE_TIME)
    if stored_on_s3?
      if download
        download_arg = 'attachment; filename=' + URI.escape(zip_file_file_name)
      else
        download_arg = nil
      end

      signer = Aws::S3::Presigner.new(client: S3_BUCKET.client)
      signer.presigned_url(:get_object,
                           bucket: S3_BUCKET.name,
                           key: zip_file.path(style)[1..-1],
                           expires_in: timeout,
                           response_content_disposition: download_arg)
    end
  end

  def stored_on_s3?
    zip_file.options[:storage].to_sym == :s3
  end

  def generate_exportable_zip(user, data, type, options = {})
    zip_input_dir = FileUtils.mkdir_p(
      File.join(Rails.root, "tmp/temp-zip-#{Time.now.to_i}")
    ).first
    zip_dir = FileUtils.mkdir_p(File.join(Rails.root, 'tmp/zip-ready')).first
    zip_file = File.new(
      File.join(zip_dir, "export-#{Time.now.to_i}.zip"),
      'w+'
    )
    fill_content(zip_input_dir, data, type, options)
    zip!(zip_input_dir, zip_file)
    self.zip_file = File.open(zip_file)
    generate_notification(user) if save
  ensure
    FileUtils.rm_rf([zip_input_dir, zip_file], secure: true)
  end

  handle_asynchronously :generate_exportable_zip

  private

  def method_missing(m, *args, &block)
    puts 'Method is missing! To use this zip_export you have to ' \
         'define a method: generate_( type )_zip.'
    object.public_send(m, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?(' generate_') || super
  end

  def fill_content(dir, data, type, options = {})
    eval("generate_#{type}_zip(dir, data, options)")
  end

  def generate_notification(user)
    notification = Notification.create(
      type_of: :deliver,
      title: I18n.t('zip_export.notification_title'),
      message:  "<a data-id='#{id}' " \
                "href='#{Rails.application
                              .routes
                              .url_helpers
                              .zip_exports_download_path(self)}'>" \
                "#{zip_file_file_name}</a>"
    )
    UserNotification.create(notification: notification, user: user)
  end

  def zip!(input_dir, output_file)
    files = Dir.entries(input_dir)
    files.delete_if { |el| el == '..' || el == '.' }
    Zip::File.open(output_file.path, Zip::File::CREATE) do |zipfile|
      files.each do |filename|
        zipfile.add(filename, input_dir + '/' + filename)
      end
    end
  end

  def generate_samples_zip(tmp_dir, data, _options = {})
    file = FileUtils.touch("#{tmp_dir}/export.csv").first
    File.open(file, 'wb') { |f| f.write(data) }
  end

  def generate_repositories_zip(tmp_dir, data, _options = {})
    file = FileUtils.touch("#{tmp_dir}/export.csv").first
    File.open(file, 'wb') { |f| f.write(data) }
  end
end
