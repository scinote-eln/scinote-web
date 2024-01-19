# frozen_string_literal: true

require 'fileutils'
require 'csv'
require 'vips'

class TeamZipExportJob < ZipExportJob
  include StringUtility

  private

  # Override
  def zip_name
    "projects_export_#{Time.now.utc.strftime('%F_%H-%M-%S_UTC')}.zip"
  end

  # Override
  def fill_content(dir, params)
    # Create team folder
    @team = Team.find(params[:team_id])
    projects = @team.projects.where(id: params[:project_ids])
    team_path = "#{dir}/#{to_filesystem_name(@team.name)}"
    FileUtils.mkdir_p(team_path)

    # Iterate through every project
    p_idx = p_archive_idx = 0
    projects.each do |project|
      idx = project.archived ? (p_archive_idx += 1) : (p_idx += 1)
      project_path = make_model_dir(team_path, project, idx)
      project_name = project_path.split('/')[-1]

      obj_filenames = { repositories: {}, assets: {}, tables: {} }

      # Change current dir for correct generation of relative links
      Dir.chdir(project_path)
      project_path = '.'

      inventories = "#{project_path}/Inventories"
      FileUtils.mkdir_p(inventories)

      repositories = project.assigned_repositories_and_snapshots

      # Iterate through every inventory repo and save it to CSV
      repositories.each_with_index do |repo, repo_idx|
        next if obj_filenames[:repositories][repo.id].present?

        obj_filenames[:repositories][repo.id] = {
          file: save_inventories_to_csv(inventories, repo, repo_idx)
        }
      end

      # Include all experiments
      ex_idx = ex_archive_idx = 0
      project.experiments.each do |experiment|
        idx = experiment.archived ? (ex_archive_idx += 1) : (ex_idx += 1)
        experiment_path = make_model_dir(project_path, experiment, idx)

        # Include all modules
        mod_pos = mod_archive_pos = 0
        experiment.my_modules.order(:workflow_order).each do |my_module|
          pos = my_module.archived ? (mod_archive_pos += 1) : (mod_pos += 1)
          my_module_path = make_model_dir(experiment_path, my_module, pos)

          # Create upper directories for both elements
          protocol_path = "#{my_module_path}/Protocol attachments"
          result_path = "#{my_module_path}/Result attachments"
          FileUtils.mkdir_p(protocol_path)
          FileUtils.mkdir_p(result_path)

          # Export protocols
          steps = my_module.protocols.map(&:steps).flatten
          obj_filenames[:assets].merge!(
            export_assets(StepAsset.where(step: steps), :step, protocol_path)
          )
          obj_filenames[:tables].merge!(
            export_tables(StepTable.where(step: steps), :step, protocol_path)
          )

          # Export results
          [false, true].each do |archived|
            obj_filenames[:assets].merge!(
              export_assets(
                ResultAsset.where(result: my_module.results.where(archived: archived)),
                :result,
                result_path,
                archived
              )
            )
          end

          [false, true].each do |archived|
            obj_filenames[:tables].merge!(
              export_tables(
                ResultTable.where(result: my_module.results.where(archived: archived)),
                :result,
                result_path,
                archived
              )
            )
          end
        end
      end

      # Generate and export whole project report HTML
      html_name = "#{project_name} Report.html"
      project_report_pdf = project.generate_teams_export_report_html(
        @user, @team, html_name, obj_filenames
      )
      File.binwrite("#{project_path}/#{html_name}", project_report_pdf)
    end
  ensure
    # Change current dir outside dir, since it will be deleted
    Dir.chdir(Rails.root)
  end

  # Create directory for project, experiment, or module
  def make_model_dir(parent_path, model, index)
    # For MyModule, the index indicates its position in project sidebar
    if model.instance_of?(MyModule)
      class_name = 'module'
      model_format = '(%<idx>s) %<name>s'
    else
      class_name = model.class.to_s.downcase.pluralize
      model_format = '%<name>s (%<idx>s)'
    end
    model_name =
      format(model_format, idx: index, name: to_filesystem_name(model.name))

    model_path = parent_path
    if model.archived
      model_path += "/Archived #{class_name}"
      FileUtils.mkdir_p(model_path)
    end
    model_path += "/#{model_name}"
    FileUtils.mkdir_p(model_path)
    model_path
  end

  # Appends given suffix to file_name and then adds original extension
  def append_file_suffix(file_name, suffix)
    ext = File.extname(file_name)
    File.basename(file_name, ext) + suffix + ext
  end

  def create_archived_results_folder(result_path)
    path = "#{result_path}/Archived attachments"
    FileUtils.mkdir_p(path) unless File.directory?(path)
    path
  end

  # Helper method to extract given assets to the directory
  def export_assets(elements, type, directory, archived = false)
    directory = create_archived_results_folder(directory) if archived && elements.present?

    asset_indexes = {}
    elements.each_with_index do |element, i|
      asset = element.asset
      preview = prepare_preview(asset)
      if type == :step
        name = "#{directory}/" \
               "#{append_file_suffix(asset.file_name, "_#{i}_Step#{element.step.position_plus_one}")}"
        if preview
          preview_name = "#{directory}/" \
                         "#{append_file_suffix(preview[:file_name], "_#{i}_Step#{element.step.position_plus_one}_preview")}"
        end
      elsif type == :result
        name = "#{directory}/#{append_file_suffix(asset.file_name, "_#{i}")}"
        preview_name = "#{directory}/#{append_file_suffix(preview[:file_name], "_#{i}_preview")}" if preview
      end

      if asset.file.attached?
        begin
          File.binwrite(name, asset.file.download)
          File.binwrite(preview_name, preview[:file_data]) if preview
        rescue ActiveStorage::FileNotFoundError
          next
        end
      end
      asset_indexes[asset.id] = {
        file: name,
        preview: preview_name
      }
    end
    asset_indexes
  end

  def prepare_preview(asset)
    if asset.previewable? && !asset.list?
      preview = asset.inline? ? asset.large_preview : asset.medium_preview

      begin
        if preview.is_a?(ActiveStorage::Preview)
          return unless preview.image.attached?

          file_name = preview.image.filename.to_s
          file_data = preview.image.download
        else
          return unless preview.processed?

          file_name = preview.blob.filename.to_s
          file_data = preview.download
        end
      rescue ActiveStorage::FileNotFoundError => e
        Rails.logger.error(e.message)
        Rails.logger.error(e.backtrace.join("\n"))
        return
      end

      {
        file_name: file_name,
        file_data: file_data
      }
    end
  end

  # Helper method to extract given tables to the directory
  def export_tables(elements, type, directory, archived = false)
    directory = create_archived_results_folder(directory) if archived && elements.present?

    table_indexes = {}
    elements.each_with_index do |element, i|
      table = element.table
      table_name = table.name.presence || 'Table'
      table_name += i.to_s

      if type == :step
        name = "#{directory}/#{to_filesystem_name(table_name)}" \
               "_#{i}_Step#{element.step.position_plus_one}.csv"
      elsif type == :result
        name = "#{directory}/#{to_filesystem_name(table_name)}.csv"
      end
      File.binwrite(name, table.to_csv)
      table_indexes[table.id] = {
        file: name
      }
    end

    table_indexes
  end

  # Helper method for saving inventories to CSV
  def save_inventories_to_csv(path, repo, idx)
    repo_name = "#{to_filesystem_name(repo.name)} (#{idx})"

    # Attachment folder
    rel_attach_path = "#{repo_name} attachments"
    attach_path = "#{path}/#{rel_attach_path}"
    FileUtils.mkdir_p(attach_path)

    # CSV file
    csv_file_path = "#{path}/#{repo_name}.csv"

    # Define headers and columns IDs
    col_ids = [-3, -4, -5, -6]
    col_ids << -9 if Repository.repository_row_connections_enabled?
    col_ids += repo.repository_columns.map(&:id)

    # Define callback function for file name
    assets = {}
    asset_counter = 0
    handle_name_func = lambda do |asset|
      file_name = append_file_suffix(asset.file_name, "_#{asset_counter}").to_s

      # Save pair for downloading it later
      assets[asset] = "#{attach_path}/#{file_name}"

      asset_counter += 1
      rel_path = "#{rel_attach_path}/#{file_name}"
      return "=HYPERLINK(\"#{rel_path}\", \"#{rel_path}\")"
    end

    # Generate CSV
    csv_data = RepositoryZipExport.to_csv(repo.repository_rows, col_ids, @user, repo, handle_name_func)
    File.binwrite(csv_file_path, csv_data.encode('UTF-8', invalid: :replace, undef: :replace))

    # Save all attachments (it doesn't work directly in callback function
    assets.each do |asset, asset_path|
      asset.file.open do |file|
        FileUtils.cp(file.path, asset_path)
      end
    rescue ActiveStorage::FileNotFoundError
      next
    end

    csv_file_path
  end

  def failed_notification_title
    I18n.t('activejob.failure_notifiable_job.item_notification_title',
           item: I18n.t('activejob.failure_notifiable_job.items.project'))
  end
end
