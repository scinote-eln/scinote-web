require 'zip'
require 'fileutils'

class ZipExport < ActiveRecord::Base
  belongs_to :user
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
    FileUtils.mkdir_p(File.join(Rails.root, 'tmp/zip-ready'))
    dir_to_zip = FileUtils.mkdir_p(
      File.join(Rails.root, "tmp/temp-zip-#{Time.now.to_i}")
    ).first
    output_file = File.new(
      File.join(Rails.root, "tmp/zip-ready/export-#{Time.now.to_i}.zip"),
      'w+'
    )
    fill_content(dir_to_zip, data, type, options)
    zip!(dir_to_zip, output_file.path)
    self.zip_file = File.open(output_file)
    generate_notification(user) if save
  end

  handle_asynchronously :generate_exportable_zip

  private

  def fill_content(dir, data, type, options = {})
    generate_csv(dir, data, options) if type == :csv
  end

  def generate_csv(tmp_dir, data, options = {})
    attributes = options.fetch(:attributes) { :attributes_missing }
    file = FileUtils.touch("#{tmp_dir}/export.csv").first
    CSV.open(file, 'wb') do |csv|
      csv << attributes
      data.each do |entity|
        csv << entity.audit_record.values_at(*attributes.map(&:to_sym))
      end
    end
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
    Zip::File.open(output_file, Zip::File::CREATE) do |zipfile|
      files.each do |filename|
        zipfile.add(filename, input_dir + '/' + filename)
      end
    end
  end
end
