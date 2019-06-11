# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

class Report::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper
  include GlobalActivitiesHelper

  include Report::DocxAction::Experiment
  include Report::DocxAction::MyModule
  include Report::DocxAction::MyModuleActivity
  include Report::DocxAction::MyModuleSamples
  include Report::DocxAction::Protocol
  include Report::DocxAction::Step
  include Report::DocxAction::StepTable
  include Report::DocxAction::StepChecklist
  include Report::DocxAction::StepAsset
  include Report::DocxAction::StepComments
  include Report::DocxAction::ResultAsset
  include Report::DocxAction::ResultTable
  include Report::DocxAction::ResultText
  include Report::DocxAction::ResultComments

  def initialize(json, docx, options)
    @json = JSON.parse(json)
    @docx = docx
    @user = options[:user]
    @report_team = options[:team]
  end

  def draw
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

    @json.each do |main_object|
      case main_object['type_of']
      when 'project_header'
        project = Project.find_by_id(main_object['id']['project_id'])
        @docx.p I18n.t('projects.reports.elements.project_header.user_time',
                       timestamp: I18n.l(project.created_at, format: :full))
        @docx.h1 I18n.t('projects.reports.elements.project_header.title', project: project.name)
        @docx.hr do
          size 18
          spacing 24
        end
      when 'experiment'
        experiment = Experiment.find_by_id(main_object['id']['experiment_id'])
        draw_experiment(experiment, main_object['children'])
      end
    end
    @docx
  end

  private

  # RTE fields support
  def html_to_word_converter(text)
    html = Nokogiri::HTML(text)
    raw_elements = recursive_children(html.css('body').children, [])

    elements = []
    temp_p = []

    # Combined raw text blocks in paragraphs
    raw_elements.each do |elem|
      if elem[:type] == 'image' || elem[:type] == 'newline'
        unless temp_p.empty?
          elements.push(type: 'p', children: temp_p)
          temp_p = []
        end
        elements.push(elem)
      elsif elem[:type] == 'br' || elem[:type] == 'text'
        temp_p.push(elem)
      end
    end
    elements.push(type: 'p', children: temp_p)
    # Draw elements
    elements.each do |elem|
      if elem[:type] == 'p'
        @docx.p do
          elem[:children].each do |text_el|
            if text_el[:type] == 'text'
              style = text_el[:style] || {}
              text text_el[:value], style
              text ' ' if text_el[:value] != ''
            elsif text_el[:type] == 'br'
              br
            end
          end
        end
      elsif elem[:type] == 'newline'
        style = elem[:style] || {}
        @docx.p elem[:value] do
          align style[:align]
          color style[:color]
          bold style[:bold]
          italic style[:italic]
          style style[:style] if style[:style]
        end
      elsif elem[:type] == 'image'
        style = elem[:style]
        @docx.img elem[:data], width: style[:width], height: style[:height], align: style[:align]
      end
    end
  end

  # Convert HTML structure to plain text structure
  def recursive_children(children, elements)
    children.each do |elem|
      if elem.class == Nokogiri::XML::Text
        style = paragraph_styling(elem.parent)
        type = style[:align] || style[:style] ? 'newline' : 'text'
        elements.push(
          type: type,
          value: elem.text.strip,
          style: style
        )
      end

      elements.push(type: 'br') if elem.name == 'br'

      if elem.name == 'img'

        image = TinyMceAsset.find_by_id(elem.attributes['data-mce-token'].value)
        dimension = FastImage.size(image.open.path)

        style = image_styling(elem, dimension)

        elements.push(
          type: 'image',
          data: image.open.path,
          style: style
        )
      end

      elements = recursive_children(elem.children, elements) if elem.children
    end
    elements
  end

  # Prepare style for text
  def paragraph_styling(elem)
    style = elem.attributes['style']
    result = {}
    result[:style] = elem.name.gsub('h', 'Heading') if elem.name.include? 'h'
    result[:bold] = true if elem.name == 'strong'
    result[:italic] = true if elem.name == 'em'
    style_keys = ['text-align', 'color']

    if style
      style_keys.each do |key|
        style_el = style.value.split(';').select { |i| (i.include? key) }[0]
        next unless style_el

        value = style_el.split(':')[1].strip if style_el
        if key == 'text-align'
          result[:align] = value.to_sym
        elsif key == 'color'
          result[:color] = value.delete('#')
        end
      end
    end
    result
  end

  # Prepare style for images
  def image_styling(elem, dimension)
    dimension[0] = elem.attributes['width'].value.to_i if elem.attributes['width']
    dimension[1] = elem.attributes['height'].value.to_i if elem.attributes['height']

    if elem.attributes['style']
      align = if elem.attributes['style'].value.include? 'margin-right'
                :center
              elsif elem.attributes['style'].value.include? 'float: right'
                :right
              else
                :left
              end
    end

    margins = Constants::REPORT_DOCX_MARGIN_LEFT + Constants::REPORT_DOCX_MARGIN_RIGHT
    max_width = (Constants::REPORT_DOCX_WIDTH - margins) / 20

    if dimension[0] > max_width
      x = max_width
      y = dimension[1] * max_width / dimension[0]
    else
      x = dimension[0]
      y = dimension[1]
    end

    {
      width: x,
      height: y,
      align: align
    }
  end

  def asset_image_preparing(asset)
    dimension = FastImage.size(asset.open.path)
    x = dimension[0]
    y = dimension[1]
    if x > 300
      y = y * 300 / x
      x = 300
    end
    @docx.img asset.open.path, width: x, height: y
  end
end

# rubocop:enable  Style/ClassAndModuleChildren
