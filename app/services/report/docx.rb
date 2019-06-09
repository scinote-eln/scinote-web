class Report::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper

  include Report::DocxAction::Experiment
  include Report::DocxAction::MyModule


  def initialize(json, docx, options)
    @json = JSON.parse(json)
    @docx = docx
    @user = options[:user]
    @team = options[:team]
  end

  def draw

    @docx.page_size do
      width   12240
      height  15840
    end

    @docx.page_margins do
      left    720
      right   720
      top     1440
      bottom  1440
    end

    @json.each do |main_object|
    case main_object['type_of']
    when 'project_header'
      project = Project.find_by_id(main_object['id']['project_id'])
      @docx.p I18n.t("projects.reports.elements.project_header.user_time", timestamp: I18n.l(project.created_at, format: :full))
      @docx.h1 I18n.t("projects.reports.elements.project_header.title", project: project.name)
      @docx.hr
      @docx.hr
    when 'experiment'
      experiment = Experiment.find_by_id(main_object['id']['experiment_id'])
      draw_experiment(experiment,main_object['children'])
    end

    @docx
    end
  end

  private 

  def html_to_word_converter(text)
    html = Nokogiri::HTML(text)
    raw_elements = recursive_children(html.css('body').children,[])

    elements = []
    temp_p = []

    raw_elements.each do |el|
      if el[:type] == 'image' || (el[:type] == 'text' && (el[:style][:align] || el[:style][:style]))
        unless temp_p.empty?
          elements.push({type: 'p', children: temp_p})
          temp_p = []
        end
        elements.push(el)
      elsif el[:type] == 'br' || (el[:type] == 'text' && el[:style][:align].nil? && el[:style][:style].nil?)
        temp_p.push(el)
      end
    end
    elements.push({type: 'p', children: temp_p})
    elements.each do |el|
      if el[:type] == 'p'
        @docx.p do
          el[:children].each do |text_el|
            case text_el[:type]
            when 'text'
              style = text_el[:style] || {}
              text text_el[:value], style
            when 'br'
              br
            end
          end
        end
      elsif el[:type] == 'text'
        style = el[:style] || {}
        @docx.p el[:value] do
         align style[:align]
         color style[:color]
         bold style[:bold]
         italic style[:italic]
         style style[:style] if style[:style]
       end
      elsif el[:type] == 'image'
        @docx.img el[:data], width: el[:width], height: el[:height], align: :center
      end
    end
  end

  def recursive_children(children,elements)
    children.each do |el|
      if el.class == Nokogiri::XML::Text
        elements.push({
          type: 'text',
          value: el.text,
          style: paragraph_styling(el.parent)
        })
      end

      if el.name == 'br'
        elements.push({type: 'br'})
      end

      if el.name == 'img'

        image = TinyMceAsset.find_by_id(el.attributes['data-mce-token'].value)
        dimension = FastImage.size(image.open.path)

        dimension[0] = el.attributes['width'].value.to_i if el.attributes['width']
        dimension[1] = el.attributes['height'].value.to_i if el.attributes['height']

        max_width = (12240 - 1440) / 20

        if dimension[0] > max_width
          x = max_width
          y = dimension[1] * max_width/dimension[0]
        else
          x = dimension[0]
          y = dimension[1]
        end

        elements.push({
          type: 'image',
          data: image.open.path,
          width: x,
          height: y
        })
      end

      elements = recursive_children(el.children,elements)  if el.children
    end
    elements
  end

  def paragraph_styling(el)
    style = el.attributes["style"]
    result={}
    if el.name.include? 'h'
      result[:style] = el.name.gsub('h','Heading')
    end
    result[:bold] = true if el.name == 'strong'
    result[:italic] = true if el.name == 'em'
    style_keys = ['text-align','color']

    if style
      style_keys.each do |key|
        style_el = style.value.split(';').select{|i| (i.include? key)}[0]
        if style_el
          value = style_el.split(':')[1].strip if style_el
          if key == 'text-align'
            result[:align] = value.to_sym
          elsif key == 'color'
            result[:color] = value.gsub('#','')
          end
        end
      end
    end
    result
  end

end