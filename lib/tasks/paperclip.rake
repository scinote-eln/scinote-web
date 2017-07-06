namespace :paperclip do

  def trim_url(url)
    url.split("?").first
  end

  def print_model_files(model, file_attr)

    model.all.each do |a|
      file = a.send file_attr
      styles = file.options[:styles]
      url = file.url

      puts trim_url(url)

      if styles
        styles.each do |style, option|
          url = file.url style
          puts trim_url(url)
        end
      end
    end
  end

  desc 'List all paperclip files'
  task files: :environment do
    print_model_files Asset, :file
    print_model_files User, :avatar
  end

  desc 'Reprocess the Assets attachents styles'
  task :reprocess, [:before] => :environment do |_, args|
    error = false
    assets = Asset
    if args.present? && args[:before].present?
      assets = assets.where('updated_at < ?', eval(args[:before]))
    end
    assets.find_each(batch_size: 100) do |asset|
      next unless asset.is_image?
      begin
        asset.file.reprocess! :medium, :large
      rescue
        error = true
        $stderr.puts "exception while processing #{asset.file_file_name} " \
                     "ID: #{asset.id}:"
      end
    end
    unless error
      $stderr.puts 'All gone well! ' \
                   'You can grab a beer now and enjoy the evening.'
    end
  end
end
