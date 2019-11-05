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

  def generate_exportable_zip(user, data, type, options = {})
    I18n.backend.date_format = user.settings[:date_format] || Constants::DEFAULT_DATE_FORMAT
    zip_input_dir = FileUtils.mkdir_p(File.join(Rails.root, "tmp/temp_zip_#{Time.now.to_i}")).first
    tmp_zip_dir = FileUtils.mkdir_p(File.join(Rails.root, 'tmp/zip-ready')).first
    tmp_zip_name = "export_#{Time.now.strftime('%F %H-%M-%S_UTC')}.zip"
    tmp_zip_file = File.new(File.join(tmp_zip_dir, tmp_zip_name), 'w+')

    fill_content(zip_input_dir, data, type, options)
    zip!(zip_input_dir, tmp_zip_file)
    zip_file.attach(io: File.open(tmp_zip_file), filename: tmp_zip_name)
    generate_notification(user) if save
  ensure
    FileUtils.rm_rf([zip_input_dir, tmp_zip_file], secure: true)
  end

  handle_asynchronously :generate_exportable_zip

  private

  def self_destruct
    ZipExport.delay(run_at: Constants::EXPORTABLE_ZIP_EXPIRATION_DAYS.days.from_now)
             .delete_expired_export(id)
  end

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
                "data-turbolinks='false' " \
                "href='#{Rails.application
                              .routes
                              .url_helpers
                              .zip_exports_download_path(self)}'>" \
                "#{zip_file_name}</a>"
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
