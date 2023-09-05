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

    insert_logo

    @docx.p do
      text I18n.t('projects.reports.new.generate_PDF.generated_on', timestamp: I18n.l(Time.zone.now, format: :full))
    end

    @docx.hr

    generate_html_styles
  end

  def insert_logo
    logo_data = File.read(Rails.root.join('app/assets/images/scinote_logo.svg'))

    @docx.img 'logo.svg' do
      data logo_data
      height 20
      width 100
      align :left
    end
  end

  def generate_html_styles
    @docx.style do
      id 'Heading1'
      name 'heading 1'
      font 'Arial'
      size Constants::REPORT_DOCX_REPORT_TITLE_SIZE
      bottom 240
      bold true
    end

    @docx.style do
      id 'Heading2'
      name 'heading 2'
      font 'Arial'
      size Constants::REPORT_DOCX_EXPERIMENT_TITLE_SIZE
      bottom Constants::REPORT_DOCX_EXPERIMENT_TITLE_SIZE * 10
      bold true
      italic false
    end

    @docx.style do
      id 'Heading3'
      name 'heading 3'
      font 'Arial'
      size Constants::REPORT_DOCX_MY_MODULE_TITLE_SIZE
      bottom Constants::REPORT_DOCX_EXPERIMENT_TITLE_SIZE * 10
      bold true
      italic false
    end

    @docx.style do
      id 'Heading4'
      name 'heading 4'
      font 'Arial'
      size Constants::REPORT_DOCX_STEP_TITLE_SIZE
      bottom Constants::REPORT_DOCX_EXPERIMENT_TITLE_SIZE * 10
      bold true
      italic false
    end

    @docx.style do
      id 'Heading5'
      name 'heading 5'
      font 'Arial'
      size Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
      bottom Constants::REPORT_DOCX_EXPERIMENT_TITLE_SIZE * 10
      bold true
      italic false
    end

    @link_style = {
      color: '2a61bb',
      bold: false
    }

    @color = {
      gray: 'a0a0a0',
      green: '2dbe61',
      concrete: 'f0f0f6'
    }
  end
end
