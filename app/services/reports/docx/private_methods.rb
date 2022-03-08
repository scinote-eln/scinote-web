# frozen_string_literal: true

module Reports::Docx::PrivateMethods
  private

  def initial_document_load
    @docx.page_size do
      width   Constants::REPORT_DOCX_WIDTH
      height  Constants::REPORT_DOCX_HEIGHT
    end

    @docx.page_margins do
      left    Constants::REPORT_DOCX_MARGIN_LEFT
      right   Constants::REPORT_DOCX_MARGIN_RIGHT
      top     Constants::REPORT_DOCX_MARGIN_TOP
      bottom  Constants::REPORT_DOCX_MARGIN_BOTTOM
    end

    @docx.page_numbers true, align: :right

    path = Rails.root.join('app', 'assets', 'images', 'logo.png')

    @docx.img path.to_s do
      height 20
      width 100
      align :left
    end
    @docx.p do
      text I18n.t('projects.reports.new.generate_PDF.generated_on', timestamp: I18n.l(Time.zone.now, format: :full))
      br
    end

    generate_html_styles
  end

  def generate_html_styles
    @docx.style do
      id 'Heading1'
      name 'heading 1'
      font 'Arial'
      size 36
      bottom 120
      bold true
    end

    @link_style = {
      color: '37a0d9',
      bold: true
    }

    @color = {
      gray: 'a0a0a0',
      green: '2dbe61'
    }
  end
end
