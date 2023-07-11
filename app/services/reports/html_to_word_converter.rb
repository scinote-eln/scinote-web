# frozen_string_literal: true

module Reports
  class HtmlToWordConverter
    def initialize(document, options = {})
      @docx = document
      @scinote_url = options[:scinote_url]
      @link_style = options[:link_style]
    end

    def html_to_word_converter(text)
      html = Nokogiri::HTML(text)
      raw_elements = recursive_children(html.css('body').children, []).compact

      # Combined raw text blocks in paragraphs
      elements = combine_docx_elements(raw_elements)

      # Draw elements
      elements.each do |elem|
        if elem[:type] == 'p'
          Reports::DocxRenderer.render_p_element(@docx, elem, scinote_url: @scinote_url, link_style: @link_style)
        elsif elem[:type] == 'table'
          Reports::DocxRenderer.render_table_element(@docx, elem)
        elsif elem[:type] == 'newline'
          style = elem[:style] || {}
          # print heading if its heading
          # Mixing heading with other style setting causes problems for Word
          if %w(h1 h2 h3 h4 h5 h6).include?(style[:style])
            @docx.public_send(style[:style], elem[:value])
          else
            @docx.p elem[:value] do
              align style[:align]
              color style[:color]
              bold style[:bold]
              italic style[:italic]
            end
          end
        elsif elem[:type] == 'image'
          Reports::DocxRenderer.render_img_element(@docx, elem)
        elsif %w(ul ol).include?(elem[:type])
          Reports::DocxRenderer.render_list_element(@docx, elem)
        end
      end
    end

    private

    def combine_docx_elements(raw_elements)
      # Word does not support some nested elements, move some elements to root level
      elements = []
      temp_p = []
      raw_elements.each do |elem|
        next unless elem

        if %w(image newline table ol ul).include? elem[:type]
          unless temp_p.blank?
            elements.push(type: 'p', children: temp_p)
            temp_p = []
          end
          elements.push(elem)
        elsif %w(br text a sup sub).include? elem[:type]
          temp_p.push(elem)
        end
      end
      elements.push(type: 'p', children: temp_p)
      elements
    end

    # Convert HTML structure to plain text structure
    # rubocop:disable Metrics/BlockLength
    def recursive_children(children, elements, skip_newline = false)
      children.each do |elem|
        if elem.class == Nokogiri::XML::Text
          next if elem.text.strip == ' ' # Invisible symbol

          style = paragraph_styling(elem.parent)
          type = !skip_newline && ((style[:align] && style[:align] != :justify) || style[:style]) ? 'newline' : 'text'

          text = smart_annotation_check(elem)

          elements.push(
            type: type,
            value: text.strip.delete(' '), # Invisible symbol
            style: style
          )
          next
        end

        if elem.name == 'br'
          elements.push(type: 'br')
          next
        end

        if elem.name == 'img'
          elements.push(img_element(elem))
          next
        end

        if elem.name == 'a'
          elements.push(link_element(elem))
          next
        end

        if elem.name == 'table'
          elements.push(tiny_mce_table_element(elem))
          next
        end

        if %w(sup sub).include?(elem.name)
          elements.push(text_formatting_element(elem))
          next
        end

        if %w(ul ol).include?(elem.name)
          elements.push(list_element(elem))
          next
        end
        elements = recursive_children(elem.children, elements, skip_newline) if elem.children
      end
      elements
    end

    # rubocop:enable Metrics/BlockLength

    def img_element(elem)
      return unless elem.attributes['data-mce-token']

      image = TinyMceAsset.find_by(id: Base62.decode(elem.attributes['data-mce-token'].value))
      return unless image

      image_path = Reports::Utils.image_prepare(image).url
      dimension = FastImage.size(image_path)

      return unless dimension

      style = image_styling(elem, dimension)

      { type: 'image', data: image_path.split('&')[0], blob: image.blob, style: style }
    end

    def link_element(elem)
      text = elem.text
      link = elem.attributes['href'].value if elem.attributes['href']
      if elem.attributes['class']&.value == 'record-info-link'
        link = nil
        text = "##{text}"
      end
      text = "##{text}" if elem.parent.attributes['class']&.value == 'atwho-inserted'
      text = "@#{text}" if elem.attributes['class']&.value == 'atwho-user-popover'
      {
        type: 'a',
        value: text,
        link: link
      }
    end

    def list_element(list_element)
      allowed_elements = %w(li ul ol a img strong em h1 h2 h2 h3 h4 h5 span p)
      data_array = list_element.children.select { |n| allowed_elements.include?(n.name) }.map do |li_child|
        li_child.children.map do |item|
          if item.is_a? Nokogiri::XML::Text
            item.text.chomp
          elsif %w(ul ol).include?(item.name)
            list_element(item)
          elsif %w(a).include?(item.name)
            link_element(item)
          elsif %w(img).include?(item.name)
            img_element(item)&.merge(bookmark_id: SecureRandom.hex)
          elsif %w(table).include?(item.name)
            tiny_mce_table_element(item).merge(bookmark_id: SecureRandom.hex)
          elsif %w(strong em h1 h2 h2 h3 h4 h5 span p).include?(item.name)
            # Pass styles and extend renderer for li with style, some limitations on li items
            # { type: 'text', value: item[:value], style: paragraph_styling(item) }
            item.children.text
          end
        end.reject(&:blank?)
      end
      { type: list_element.name, data: data_array }
    end

    def smart_annotation_check(elem)
      return "[#{elem.text}]" if elem.parent.attributes['class']&.value == 'sa-type'

      elem.text
    end

    # Prepare style for text
    def paragraph_styling(elem)
      style = elem.attributes['style']
      result = {}
      result[:style] = elem.name if elem.name.include? 'h'
      result[:bold] = true if elem.name == 'strong'
      result[:italic] = true if elem.name == 'em'
      style_keys = %w(text-align color text-decoration)

      if style
        style_keys.each do |key|
          style_el = style.value.split(';').select { |i| (i.include? key) }[0]
          next unless style_el

          value = style_el.split(':')[1].strip if style_el

          if key == 'text-align'
            result[:align] = value.to_sym
          elsif key == 'color' && Reports::Utils.calculate_color_hsp("##{normalized_hex_color(value)}") < 190
            result[:color] = normalized_hex_color(value)
          elsif key == 'text-decoration' && value == 'underline'
            result[:underline] = true
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
        align: align,
        max_width: max_width
      }
    end

    def tiny_mce_table_element(table_element)
      # array of elements
      rows = table_element.css('tbody').first.children.map do |row|
        next unless row.name == 'tr'

        cells = row.children.map do |cell|
          next unless cell.name == 'td'

          # Parse cell content
          formated_cell = recursive_children(cell.children, [], true)

          # Combine text elements to single paragraph
          formated_cell = combine_docx_elements(formated_cell)
          formated_cell
        end.reject(&:blank?)
        { type: 'tr', data: cells }
      end.reject(&:blank?)
      { type: 'table', data: rows }
    end

    def text_formatting_element(element)
      { type: element.name, value: element.text }
    end

    def normalized_hex_color(color)
      return color.delete('#') if color.start_with?('#')

      color.scan(/\d+/).map(&:to_i).map { |c| c.to_s(16).rjust(2, '0').upcase }.join
    end
  end
end
