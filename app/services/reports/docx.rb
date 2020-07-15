# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

class Reports::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper
  include GlobalActivitiesHelper

  Dir[File.join(File.dirname(__FILE__), 'docx') + '**/*.rb'].each do |file|
    include_module = File.basename(file).gsub('.rb', '').split('_').map(&:capitalize).join
    include "Reports::Docx::#{include_module}".constantize
  end

  def initialize(json, docx, options)
    @json = JSON.parse(json)
    @docx = docx
    @user = options[:user]
    @report_team = options[:team]
    @link_style = {}
    @color = {}
    @scinote_url = options[:scinote_url][0..-2]
  end

  def draw
    initial_document_load

    @json.each do |subject|
      public_send("draw_#{subject['type_of']}", subject)
    end
    @docx
  end

  def self.link_prepare(scinote_url, link)
    link[0] == '/' ? scinote_url + link : link
  end

  def self.render_p_element(docx, element, options = {})
    scinote_url = options[:scinote_url]
    link_style = options[:link_style]
    docx.p do
      element[:children].each do |text_el|
        if text_el[:type] == 'text'
          style = text_el[:style] || {}
          text text_el[:value], style
          text ' ' if text_el[:value] != ''
        elsif text_el[:type] == 'br' && !options[:skip_br]
          br
        elsif text_el[:type] == 'a'
          if text_el[:link]
            link_url = Reports::Docx.link_prepare(scinote_url, text_el[:link])
            link text_el[:value], link_url, link_style
          else
            text text_el[:value], link_style
          end
          text ' ' if text_el[:value] != ''
        end
      end
    end
  end

  def self.render_img_element(docx, element, options = {})
    style = element[:style]

    if options[:table]
      max_width = (style[:max_width] / options[:table][:columns].to_f)
      if style[:width] > max_width
        style[:height] = (max_width / style[:width].to_f) * style[:height]
        style[:width] = max_width
      end
    end

    docx.img element[:data] do
      data element[:blob].download
      width style[:width]
      height style[:height]
      align style[:align] || :left
    end
  end
end

# rubocop:enable  Style/ClassAndModuleChildren
