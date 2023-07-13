# frozen_string_literal: true

module Reports
  class DocxRenderer
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
            Reports::DocxRenderer.render_link_element(self, text_el, options)
          elsif text_el[:type] == 'sup'
            text text_el[:value] do
              vertical_align 'superscript'
            end
          elsif text_el[:type] == 'sub'
            text text_el[:value] do
              vertical_align 'subscript'
            end
          end
        end
      end
    end

    def self.render_link_element(node, link_item, options = {})
      scinote_url = options[:scinote_url]
      link_style = options[:link_style]

      if link_item[:link]
        link_url = Reports::Utils.link_prepare(scinote_url, link_item[:link])
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
      bookmark_items = Reports::DocxRenderer.recursive_list_items_renderer(docx, element)

      bookmark_items.each_with_index do |(key, item), index|
        if item[:type] == 'image'
          docx.bookmark_start id: index, name: key
          docx.p do
            br
            text item[:blob]&.filename.to_s
          end
          Reports::DocxRenderer.render_img_element(docx, item)
          docx.bookmark_end id: index
        elsif item[:type] == 'table'
          docx.bookmark_start id: index, name: key

          # Bookmark won't work with table only, empty p element added
          docx.p do
            br
            text ''
          end
          Reports::DocxRenderer.render_table_element(docx, item, options)
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
                  Reports::DocxRenderer.recursive_list_items_renderer(self, item, bookmark_items: bookmark_items)
                elsif %w(a).include?(item[:type])
                  Reports::DocxRenderer.render_link_element(self, item)
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
                elsif %w(text).include?(item[:type])
                  # TODO: Text with styles, not working yet.
                  style = item[:style] || {}
                  text item[:value], style
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
                Reports::DocxRenderer.render_p_element(c, content, options.merge({ skip_br: true }))
              elsif content[:type] == 'table'
                Reports::DocxRenderer.render_table_element(c, content, options)
              elsif content[:type] == 'image'
                Reports::DocxRenderer.render_img_element(c, content, table: { columns: row[:data].length })
              end
            end
          end
          docx_row.push(docx_cell)
        end
        docx_table.push(docx_row)
      end
      docx.table docx_table, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE
    end

    def self.render_asset_image(docx, asset)
      return unless asset

      asset_preview = Reports::Utils.image_prepare(asset)

      dimension = FastImage.size(asset_preview.processed.url)
      return unless dimension

      x = dimension[0]
      y = dimension[1]
      if x > 300
        y = y * 300 / x
        x = 300
      end

      blob_data = if asset_preview.instance_of? ActiveStorage::Preview
                    asset_preview.image.download
                  else
                    asset_preview.blob.download
                  end

      docx.img asset_preview.processed.url.split('&')[0] do
        data blob_data
        width x
        height y
      end
    rescue SocketError, Caracal::Errors::InvalidModelError => e # invalid URL or broken image
      Rails.logger.warn("Unable to render docx image due to #{e.class}: #{e}")
      nil
    end
  end
end
