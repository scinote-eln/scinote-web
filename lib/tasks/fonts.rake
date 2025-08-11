# frozen_string_literal: true

namespace :fonts do
  task convert_to_base64: :environment do
    icons_path = Rails.root.join('vendor/assets/stylesheets/fonts/SN-icon-font.woff2')
    css_file_path = Rails.root.join('app/assets/stylesheets/reports_pdf_icons.sass.scss')

    if File.exist?(icons_path)

      base64_content = `base64 -i #{icons_path}`.strip.gsub(/\n+/, '')

      css = "
        @font-face {
          font-family: \"SN-icon-font\";
          src: url(data:font/woff2;base64,#{base64_content});
        }
      "

      File.open(css_file_path, 'w') do |file|
        file.write(css)
      end

      Rails.logger.info("Icon font file converted to base64 and written to #{css_file_path}")
    else
      Rails.logger.warn("Icon font file not found at #{icons_path}")
    end
  end
end
