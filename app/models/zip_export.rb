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

  has_one_attached :zip_file

  after_create :self_destruct

  def self.delete_expired_export(id)
    export = find_by_id(id)
    export&.destroy
  end

  def zip_file_name
    return '' unless zip_file.attached?

    zip_file.blob&.filename&.to_s
  end

  def zip!(input_dir, output_file)
    entries = Dir.glob('**/*', base: input_dir)
    Zip::File.open(output_file, create: true) do |zipfile|
      entries.each do |entry|
        zipfile.add(entry, "#{input_dir}/#{entry}")
      end
    end
  end

  def generate_exportable_zip(user, data, type, options = {})
    I18n.backend.date_format = user.settings[:date_format] || Constants::DEFAULT_DATE_FORMAT
    zip_input_dir = FileUtils.mkdir_p(File.join(Rails.root, "tmp/temp_zip_#{Time.now.to_i}")).first
    tmp_zip_dir = FileUtils.mkdir_p(File.join(Rails.root, 'tmp/zip-ready')).first
    tmp_full_zip_name = File.join(tmp_zip_dir, "export_#{Time.now.strftime('%F %H-%M-%S_UTC')}.zip")

    fill_content(zip_input_dir, data, type, options)
    zip!(zip_input_dir, tmp_full_zip_name)
    zip_file.attach(io: File.open(tmp_full_zip_name), filename: tmp_full_zip_name)
    generate_notification(user) if save
  ensure
    FileUtils.rm_rf([zip_input_dir, tmp_full_zip_name], secure: true)
  end

  handle_asynchronously :generate_exportable_zip

  private

  def self_destruct
    ZipExport.delay(run_at: Constants::EXPORTABLE_ZIP_EXPIRATION_DAYS.days.from_now)
             .delete_expired_export(id)
  end

  def method_missing(method_name, *args, &block)
    return super unless method_name.to_s.start_with?('generate_')

    raise StandardError, 'Method is missing! To use this zip_export you have to define a method: generate_( type )_zip.'
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?('generate_') || super
  end

  def fill_content(dir, data, type, options = {})
    eval("generate_#{type}_zip(dir, data, options)")
  end

  def generate_notification(user)
    notification = Notification.create(
      type_of: :deliver,
      title: I18n.t('zip_export.notification_title'),
      message:  "<a data-id='#{id}' " \
                "data-turbolinks='false' " \
                "href='#{Rails.application
                              .routes
                              .url_helpers
                              .zip_exports_download_path(self)}'>" \
                "#{zip_file_name}</a>"
    )
    UserNotification.create(notification: notification, user: user)
  end

  def generate_repositories_zip(tmp_dir, data, _options = {})
    file = FileUtils.touch("#{tmp_dir}/export.csv").first
    File.open(file, 'wb') { |f| f.write(data) }
  end
end
