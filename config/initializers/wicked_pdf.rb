# frozen_string_literal: true

WickedPdf.config ||= {}

ENV['PATH'].split(':').each do |path|
  exe_path = File.join(path, 'wkhtmltopdf')
  WickedPdf.config[:exe_path] = File.join(path, 'wkhtmltopdf') if File.file?(exe_path)
  WickedPdf.config[:allow] = Rails.public_path
end
