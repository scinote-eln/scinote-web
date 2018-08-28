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

  def generate_export_all_zip(user, data, type, options = {})
    FileUtils.mkdir_p(File.join(Rails.root, 'tmp/zip-ready'))
    dir_to_zip = FileUtils.mkdir_p(
      File.join(Rails.root, "tmp/temp-zip-#{Time.now.to_i}")
    ).first
    output_file = File.new(
      File.join(Rails.root,
                "tmp/zip-ready/projects_export-timestamp-#{Time.now.to_i}.zip"
               ),
      'w+'
    )
    fill_content(dir_to_zip, data, type, options)
    zip_all!(dir_to_zip, output_file.path)
    self.zip_file = File.open(output_file)
    generate_notification(user) if save
  end

  handle_asynchronously :generate_exportable_zip
  #handle_asynchronously :generate_export_all_zip

  private

  # Zip the input directory.
  def write()
    entries = Dir.entries(@inputDir); entries.delete("."); entries.delete("..")
    io = Zip::File.open(@outputFile, Zip::File::CREATE);

    writeEntries(entries, "", io)
    io.close();
  end

  # A helper method to make the recursion work.
  private
  def writeEntries(input_dir, entries, path, io)

    entries.each { |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(input_dir, zipFilePath)
      puts "Deflating " + diskFilePath
      if  File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..")
        writeEntries(input_dir, subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
      end
    }
  end

  #def method_missing(m, *args, &block)
    #puts 'Method is missing! To use this zip_export you have to ' \
         #'define a method: generate_( type )_zip.'
    #object.public_send(m, *args, &block)
  #end

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
    Zip::File.open(output_file, Zip::File::CREATE) do |zipfile|
      files.each do |filename|
        zipfile.add(filename, input_dir + '/' + filename)
      end
    end
  end

  def zip_all!(input_dir, output_file)
    files = Dir.entries(input_dir)
    files.delete_if { |el| el == '..' || el == '.' }
    Zip::File.open(output_file, Zip::File::CREATE) do |zipfile|
      #files.each do |filename|
        #zipfile.add(filename, input_dir + '/' + filename)
      #end

      writeEntries(input_dir, files, "", zipfile)
    end
  end

  def handle_asset_name(name, type)
    if type == :step


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

  MAX_NAME_SIZE = 20
  def handle_name(name)
    # Handle reserved directories
    if name == '..'
      return '__'
    elsif name == '.'
      return '.'
    end

    # Truncate and replace reserved characters
    name = name[0, MAX_NAME_SIZE].gsub(/[*":<>?\/\\|~]/, '_')

    # Remove control characters
    name = name.chars.map{|s| s.ord}.select{|s| (s > 31 && s < 127) || s > 127}.pack("U*")

    # Remove leading hyphens, trailing dots/spaces
    name.gsub(/^-|\.+$| +$/, '_')
  end

  def export_assets(assets, directory)
    # Helper method to extract given assets to the directory
    assets.each_with_index do |asset, i|
      file = FileUtils.touch("#{directory}/#{asset.file_file_name}_#{i}").first
      File.open(file, 'wb') { |f| f.write(asset.open.read) }
    end
  end

  def export_step_assets(assets, directory)
    # Helper method to extract given step assets to the directory
    assets.each_with_index do |step_asset, i|
      asset = step_asset.asset
      file = FileUtils.touch(
        "#{directory}/#{asset.file_file_name}_#{i}_Step#{step_asset.step.position+1}"
      ).first
      File.open(file, 'wb') { |f| f.write(asset.open.read) }
    end
  end

  def export_step_tables(tables, directory)
    # Helper method to extract given tables to the directory
    tables.each_with_index do |table, i|
      table_name = table.name.presence || 'Table'
      table_name += i.to_s
      file = FileUtils.touch(
        "#{directory}/#{handle_name(table_name)}_#{i}_Step#{step_asset.step.position+1}}.csv"
      ).first
      File.open(file, 'wb') { |f| f.write(table.contents) }
    end
  end

  def export_tables(tables, directory)
    # Helper method to extract given tables to the directory
    tables.each_with_index do |table, i|
      table_name = table.name.presence || 'Table'
      table_name += i.to_s
      file = FileUtils.touch("#{directory}/#{table_name}.csv").first
      File.open(file, 'wb') { |f| f.write(table.contents) }
    end
  end

  def save_inventories_to_csv(path, repo, repo_rows, id)
    # Helper method for saving inventories to CSV
    repo_name = handle_name(repo.name) + "_#{id}"
    file = FileUtils.touch("#{path}/#{repo_name}.csv").first

    # Attachment folder
    rel_attach_path = "#{repo_name}_ATTACHMENTS"
    attach_path = "#{path}/#{rel_attach_path}"
    FileUtils.mkdir_p(attach_path)

    # Define headers and columns IDs
    headers = ['ID', 'Name', 'Added on', 'Added by'] +
              repo.repository_columns.map{|x| x.name}
    col_ids = repo.repository_columns.map{|x| x.id}

    # Generate CSV
    assets = []
    csv_data = CSV.generate do |csv|
      csv << headers

      repo_rows.each do |row|
        csv_row = [row.id, row.name, row.created_at, row.created_by.name]
        #  TODO: take care of uneven number of columns
        row.repository_cells.each do |cell|
          case cell.value_type
          when 'RepositoryAssetValue'
            csv_row << "#{rel_attach_path}/#{cell.value.asset.file_file_name}"
            assets << cell.value.asset
          when 'RepositoryListValue'
            csv_row << cell.value.formatted
          when 'RepositoryDateValue'
            csv_row << cell.value.formatted
          when 'RepositoryTextValue'
            csv_row << cell.value.formatted
          end
        end
        csv << csv_row
      end
    end
    File.open(file, 'wb') { |f| f.write(csv_data) }

    # Save all attachments
    assets.each_with_index do |asset, i|
      file = FileUtils.touch("#{attach_path}/#{asset.file_file_name}_#{i}").first
      File.open(file, 'wb') { |f| f.write(asset.open.read) }
    end
  end


  def generate_teams_zip(tmp_dir, data, _options = {})
    # Export all functionality
    # Create team folder
    team = _options[:team]
    team_path = "#{tmp_dir}/#{handle_name(team.name)}"
    FileUtils.mkdir_p(team_path)

    # Create Projects folders
    FileUtils.mkdir_p("#{team_path}/Projects")
    FileUtils.mkdir_p("#{team_path}/Archived projects")

    # Iterate through every project
    data.each_with_index do |(id, p), ind|
        project_name = handle_name(p.name) + "_#{ind}"
        root = p.archived ? "#{team_path}/Archived projects" : "#{team_path}/Projects"
        root += "/#{project_name}"
        FileUtils.mkdir_p(root)

        file = FileUtils.touch("#{root}/#{project_name}_REPORT.pdf").first

        inventories = "#{root}/Inventories"
        FileUtils.mkdir_p(inventories)

        # Find all assigned inventories through all tasks in the project
        task_ids = p.project_my_modules
        repo_rows = RepositoryRow.joins(:my_modules).where(my_modules:
                                                           { id: task_ids }
                                                          ).distinct

        # Iterate through every inventory repo and save it to CSV
        repo_rows.map{|x| x.repository}.uniq.each_with_index do |repo, repo_ind|
          curr_repo_rows = repo_rows.select{|x| x.repository_id == repo.id}
          save_inventories_to_csv(inventories, repo, curr_repo_rows, repo_ind)
        end

        # Include all experiments
        p.experiments.each_with_index do |ex, ex_ind|
          experiment_path = "#{root}/#{handle_name(ex.name)}_#{ex_ind}"
          FileUtils.mkdir_p(experiment_path)

          # Include all modules
          ex.my_modules.each_with_index do |my_module, mod_ind|
            my_module_path = "#{experiment_path}/#{handle_name(my_module.name)}_#{mod_ind}"
            FileUtils.mkdir_p(my_module_path)

            protocol_path = "#{my_module_path}/Protocol attachments"
            result_path = "#{my_module_path}/Result attachments"
            FileUtils.mkdir_p(protocol_path)
            FileUtils.mkdir_p(result_path)

            steps = my_module.protocols.map{ |p| p.steps }.flatten
            export_step_assets(StepAsset.where(step: steps), protocol_path)
            export_tables(StepTable.where(step: steps).map {|s| s.table}, protocol_path)

            export_assets(ResultAsset.where(result: my_module.results).map {|r| r.asset}, result_path)
            export_tables(ResultTable.where(result: my_module.results).map {|r| r.table}, result_path)
          end
        end
    end
  end

end
