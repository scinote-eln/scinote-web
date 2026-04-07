# frozen_string_literal: true

module ScinoteTemplateDocx
  def prepare_docx
    settings = @settings
    report = @report
    subdomain = parse_subdomain

    @docx.page_numbers true, align: :right

    insert_logo

    @docx.p do
      if settings['report_info_metadata']
        text I18n.t('projects.reports.new.generate_PDF.generated_on_with_info', subdomain: subdomain,
                                                                                timestamp: I18n.l(Time.zone.now, format: :full),
                                                                                reportid: report.code,
                                                                                version: Scinote::Application::VERSION)
      else
        text I18n.t('projects.reports.new.generate_PDF.generated_on', timestamp: I18n.l(Time.zone.now, format: :full))
      end
    end

    @docx.hr

    @report.root_elements.each do |subject|
      public_send("draw_#{subject.type_of}", subject)
    end
  end
end
