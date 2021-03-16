# frozen_string_literal: true

module Reports
  class DocxJob < ApplicationJob
    queue_as :reports

    def perform(report, data, user, team, root_url)
      file = Tempfile.new(['report', '.docx'])
      begin
        docx = Caracal::Document.new(file.path)
        Reports::Docx.new(data, docx, user: user, team: team, scinote_url: root_url).draw
        docx.save
        report.docx_file.attach(io: file, filename: 'report.docx')
        report.update!(docx_file_processing: false)
      ensure
        file.close
        file.unlink
      end
    end
  end
end
