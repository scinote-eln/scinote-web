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

  desc "List all paperclip files"
  task files: :environment do
    print_model_files Asset, :file
    print_model_files User, :avatar
  end

end
