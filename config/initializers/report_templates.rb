# frozen_string_literal: true

Dir.chdir(Rails.root.join('app/views/reports/templates')) do
  templates = Dir.glob('*').select { |entry| File.directory?(entry) }
  templates.each do |template|
    next if Extends::REPORT_TEMPLATES[template.to_sym].present?

    Extends::REPORT_TEMPLATES[template.to_sym] =
      if File.file?("#{template}/name.txt")
        File.open("#{template}/name.txt").read.strip
      else
        template
      end
  end
end
