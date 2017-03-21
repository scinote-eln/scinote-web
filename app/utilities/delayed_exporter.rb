require 'zip'
require 'tmpdir'

class DelayedExporter
  include Rails.application.routes.url_helpers

  def initialize(options = {})
    @user = options.fetch(:user) { :user_must_be_present }
    @zip_export = ZipExport.new(user: @user)
  end

  def run(&collection)
    Delayed::Job.enqueue(setup(&collection))
  end

  def setup
    temp_dir = Dir.mktempdir
    zip_path = File.join(temp_dir, 'export.zip')
    Zip::ZipFile.open(zip_path, true) do |zipfile|
      yield(zipfile) if block_given?
    end
    @zip_export.zip_file = File.open(zip_path)
    generate_notification if @zip_export.save
  end

  private

  def generate_notification
    notification = Notification.create(
      type_of: :system_message,
      title: t('zip_export.notification_title'),
      message: zip_exports_download_url(@zip_export)
    )
    UserNotification.create(notification: notification, user: @user.id)
  end
end
