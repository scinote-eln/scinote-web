# frozen_string_literal: true

module ScinoteTemplateDocx
  def prepare_docx
    @docx.page_numbers true, align: :right

    insert_logo

    @docx.p do
      text I18n.t('projects.reports.new.generate_PDF.generated_on', timestamp: I18n.l(Time.zone.now, format: :full))
    end

    @docx.hr

    @report.root_elements.each do |subject|
      public_send("draw_#{subject.type_of}", subject)
    end
  end
end
