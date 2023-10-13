# frozen_string_literal: true

class ZipExportJob < ApplicationJob
  include FailedDeliveryNotifiableJob

  def perform(user_id:, params: {})
    @user = User.find(user_id)
    I18n.backend.date_format = @user.settings[:date_format] || Constants::DEFAULT_DATE_FORMAT
    ZipExport.transaction do
      @zip_export = ZipExport.create!(user: @user)
      zip_input_dir = FileUtils.mkdir_p(Rails.root.join("tmp/temp_zip_#{Time.now.to_i}").to_s).first
      zip_dir = FileUtils.mkdir_p(Rails.root.join('tmp/zip-ready').to_s).first
      full_zip_name = File.join(zip_dir, zip_name)

      fill_content(zip_input_dir, params)
      @zip_export.zip!(zip_input_dir, full_zip_name)
      @zip_export.zip_file.attach(io: File.open(full_zip_name), filename: zip_name)
      generate_notification!
    ensure
      FileUtils.rm_rf([zip_input_dir, full_zip_name], secure: true)
    end
  ensure
    I18n.backend.date_format = nil
  end

  private

  def zip_name
    "export_#{Time.now.utc.strftime('%F %H-%M-%S_UTC')}.zip"
  end

  def fill_content(dir, params)
    raise NotImplementedError
  end

  def generate_notification!
    DeliveryNotification.with(
      title: I18n.t('zip_export.notification_title'),
      message: "<a data-id='#{@zip_export.id}' " \
                "data-turbolinks='false' " \
                "href='#{Rails.application
                              .routes
                              .url_helpers
                              .zip_exports_download_path(@zip_export)}'>" \
                "#{@zip_export.zip_file_name}</a>"
    ).deliver(@user)
  end
end
