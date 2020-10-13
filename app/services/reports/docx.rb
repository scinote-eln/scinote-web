# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

class Reports::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper
  include GlobalActivitiesHelper
  include Canaid::Helpers::PermissionsHelper

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
    docx.p do
      element[:children].each do |text_el|
        if text_el[:type] == 'text'
          style = text_el[:style] || {}
          text text_el[:value], style
          text ' ' if text_el[:value] != ''
        elsif text_el[:type] == 'br' && !options[:skip_br]
          br
        elsif text_el[:type] == 'a'
          Reports::Docx.render_link_element(self, text_el, options)
        end
      end
    end
  end

  def self.render_link_element(node, link_item, options = {})
    scinote_url = options[:scinote_url]
    link_style = options[:link_style]

    if link_item[:link]
      link_url = Reports::Docx.link_prepare(scinote_url, link_item[:link])
      node.link link_item[:value], link_url, link_style
    else
      node.text link_item[:value], link_style
    end
    node.text ' ' if link_item[:value] != ''
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

  def self.render_list_element(docx, element, options = {})
    bookmark_items = Reports::Docx.recursive_list_items_renderer(docx, element)

    bookmark_items.each_with_index do |(key, item), index|
      if item[:type] == 'image'
        docx.bookmark_start id: index, name: key
        docx.p do
          br
          text item[:blob]&.filename.to_s
        end
        Reports::Docx.render_img_element(docx, item)
        docx.bookmark_end id: index
      elsif item[:type] == 'table'
        docx.bookmark_start id: index, name: key

        # Bookmark won't work with table only, empty p element added
        docx.p do
          br
          text ''
        end
        Reports::Docx.render_table_element(docx, item, options)
        docx.bookmark_end id: index
      end
    end
  end

  # rubocop:disable Metrics/BlockLength
  def self.recursive_list_items_renderer(node, element, bookmark_items: {})
    node.public_send(element[:type]) do
      element[:data].each do |values_array|
        li do
          values_array.each do |item|
            case item
            when Hash
              if %w(ul ol li).include?(item[:type])
                Reports::Docx.recursive_list_items_renderer(self, item, bookmark_items: bookmark_items)
              elsif %w(a).include?(item[:type])
                Reports::Docx.render_link_element(self, item)
              elsif %w(image).include?(item[:type])
                bookmark_items[item[:bookmark_id]] = item
                link I18n.t('projects.reports.renderers.lists.appended_image',
                            name: item[:blob]&.filename), item[:bookmark_id] do
                  internal true
                end
              elsif %w(table).include?(item[:type])
                bookmark_items[item[:bookmark_id]] = item
                link I18n.t('projects.reports.renderers.lists.appended_table'), item[:bookmark_id] do
                  internal true
                end
              end
            else
              text item
            end
          end
        end
      end
    end
    bookmark_items
  end
  # rubocop:enable Metrics/BlockLength

  def self.render_table_element(docx, element, options = {})
    docx_table = []
    element[:data].each do |row|
      docx_row = []
      row[:data].each do |cell|
        docx_cell = Caracal::Core::Models::TableCellModel.new do |c|
          cell.each do |content|
            if content[:type] == 'p'
              Reports::Docx.render_p_element(c, content, options.merge({ skip_br: true }))
            elsif content[:type] == 'table'
              Reports::Docx.render_table_element(c, content, options)
            elsif content[:type] == 'image'
              Reports::Docx.render_img_element(c, content, table: { columns: row.children.length / 3 })
            end
          end
        end
        docx_row.push(docx_cell)
      end
      docx_table.push(docx_row)
    end
    docx.table docx_table, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
