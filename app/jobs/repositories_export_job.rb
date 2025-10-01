# frozen_string_literal: true

class RepositoriesExportJob < ApplicationJob
  include StringUtility
  include FailedDeliveryNotifiableJob

  def perform(file_type, repository_ids, user_id:, team_id:)
    @user = User.find(user_id)
    @team = Team.find(team_id)
    @repositories = Repository.readable_by_user(@user, @team).where(id: repository_ids).order(:id)
    @file_type = file_type.to_sym
    zip_input_dir = FileUtils.mkdir_p(Rails.root.join("tmp/temp_zip_#{Time.now.to_i}")).first
    zip_dir = FileUtils.mkdir_p(Rails.root.join('tmp/zip-ready')).first

    zip_name = "inventories_export_#{Time.now.utc.strftime('%F_%H-%M-%S_UTC')}.zip"
    full_zip_name = File.join(zip_dir, zip_name)

    fill_content(zip_input_dir)
    ZipExport.transaction do
      @zip_export = ZipExport.create!(user: @user)
      @zip_export.zip!(zip_input_dir, full_zip_name)
      @zip_export.zip_file.attach(io: File.open(full_zip_name), filename: zip_name)
      generate_notification
    end
  ensure
    FileUtils.rm_rf([zip_input_dir, full_zip_name], secure: true)
  end

  private

  def fill_content(tmp_dir)
    # Create team dir
    team_path = "#{tmp_dir}/#{to_filesystem_name(@team.name)}"
    FileUtils.mkdir_p(team_path)
    @repositories.each_with_index do |repository, idx|
      save_repository_as_file(team_path, repository, idx)
    end
  end

  def save_repository_as_file(path, repository, idx)
    repository_name = "#{to_filesystem_name(repository.name)} (#{idx})"

    # Attachments dir
    relative_attachments_path = "#{repository_name} attachments"
    attachments_path = "#{path}/#{relative_attachments_path}"
    FileUtils.mkdir_p(attachments_path)

    # File creation
    repository_items_file_name = FileUtils.touch("#{path}/#{repository_name}.#{@file_type}").first

    # Define headers and columns IDs
    col_ids = [-3, -4, -5, -6, -7, -8, -9, -10]
    col_ids << -11 if Repository.repository_row_connections_enabled?
    col_ids << -12 if StorageLocation.storage_locations_enabled?
    col_ids += repository.repository_columns.map(&:id)

    # Define callback function for file name
    assets = {}
    asset_counter = 0
    handle_name_func = lambda do |asset|
      file_name = append_file_suffix(asset.file_name, "_#{asset_counter}").to_s

      # Save pair for downloading it later
      assets[asset] = "#{attachments_path}/#{file_name}"

      asset_counter += 1
      relative_path = "#{relative_attachments_path}/#{file_name}"
      return "=HYPERLINK(\"#{relative_path}\", \"#{relative_path}\")"
    end

    # Generate CSV / XLSX
    service = RepositoryExportService
              .new(@file_type, repository.repository_rows, col_ids, repository, handle_name_func)
    exported_data = service.export!

    File.binwrite(repository_items_file_name, exported_data)

    # Save all attachments (it doesn't work directly in callback function
    assets.each do |asset, asset_path|
      asset.file.open do |file|
        FileUtils.mv(file.path, asset_path)
      end
    end
  end

  def append_file_suffix(file_name, suffix)
    ext = File.extname(file_name)
    file_name = to_filesystem_name(file_name)
    File.basename(file_name, ext) + suffix + ext
  end

  def generate_notification
    DeliveryNotification.send_notifications(
      {
        title: I18n.t('zip_export.notification_title'),
        message: "<a data-id='#{@zip_export.id}' " \
                      "data-turbolinks='false' " \
                      "href='#{Rails.application
                                    .routes
                                    .url_helpers
                                    .zip_exports_download_export_all_path(@zip_export)}'>" \
                      "#{@zip_export.zip_file_name}</a>",
        user: @user
      }
    )
  end

  # Overrides method from FailedDeliveryNotifiableJob concern
  def failed_notification_title
    I18n.t('activejob.failure_notifiable_job.item_notification_title',
           item: I18n.t('activejob.failure_notifiable_job.items.repository'))
  end
end
