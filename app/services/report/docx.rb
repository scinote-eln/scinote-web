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
    recursive_children(html.css('body').children)
  end

  def recursive_children(children)
    children.each do |el|
      if el.class == Nokogiri::XML::Text
        if el.parent.attributes["style"]
          el_align = el.parent.attributes["style"].value.split(';').select{|i| (i.include? 'text-align')}[0]
        end
        @docx.p el.text do
          align el_align.split(':')[1].strip.to_sym if el_align
        end
      end

      if el.name == 'img'

        image = TinyMceAsset.find_by_id(el.attributes['data-mce-token'].value)
        dimension = FastImage.size(image.open.path)
        @docx.img image.open.path, width: dimension[0], height: dimension[1]
      end

      recursive_children(el.children)  if el.children
    end
  end

end