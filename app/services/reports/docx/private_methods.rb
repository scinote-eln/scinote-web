# frozen_string_literal: true

module PrivateMethods
  private

  # RTE fields support
  def html_to_word_converter(text)
    link_style = @link_style
    scinote_url = @scinote_url
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
      elsif %w(br text a).include? elem[:type]
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
            elsif text_el[:type] == 'a'
              if text_el[:link]
                link text_el[:value], scinote_url + text_el[:link], link_style
              else
                text text_el[:value], link_style
              end
              text ' ' if text_el[:value] != ''
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
        @docx.img elem[:data], width: style[:width], height: style[:height], align: (style[:align] || :left)
      end
    end
  end

  # Convert HTML structure to plain text structure
  def recursive_children(children, elements)
    children.each do |elem|
      if elem.class == Nokogiri::XML::Text
        style = paragraph_styling(elem.parent)
        type = (style[:align] && style[:align] != :justify) || style[:style] ? 'newline' : 'text'
        elements.push(
          type: type,
          value: elem.text.strip,
          style: style
        )
        next
      end

      if elem.name == 'br'
        elements.push(type: 'br')
        next
      end

      if elem.name == 'img' && elem.attributes['data-mce-token']

        image = TinyMceAsset.find_by_id(elem.attributes['data-mce-token'].value)

        image_path = image_path(image)

        dimension = FastImage.size(image_path)

        style = image_styling(elem, dimension)

        elements.push(
          type: 'image',
          data: image_path,
          style: style
        )
        next
      end

      if elem.name == 'a'
        elements.push(link_prepare(elem))
        next
      end

      elements = recursive_children(elem.children, elements) if elem.children
    end
    elements
  end

  def link_prepare(elem)
    text = elem.text
    link = elem.attributes['href'].value if elem.attributes['href']
    link = nil if elem.attributes['class'] && elem.attributes['class'].value == 'record-info-link'
    {
      type: 'a',
      value: text,
      link: link
    }
  end

  # Prepare style for text
  def paragraph_styling(elem)
    style = elem.attributes['style']
    result = {}
    result[:style] = elem.name if elem.name.include? 'h'
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
    image_path = image_path(asset)

    dimension = FastImage.size(image_path)
    x = dimension[0]
    y = dimension[1]
    if x > 300
      y = y * 300 / x
      x = 300
    end
    @docx.img image_path, width: x, height: y
  end

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

    generate_html_styles
  end

  def generate_html_styles
    @docx.style do
      id 'h1'
      name 'h1'
      bold true
      size 64
    end

    @docx.style do
      id 'h2'
      name 'h2'
      bold true
      size 48
    end

    @docx.style do
      id 'h3'
      name 'h3'
      bold true
      size 36
    end

    @docx.style do
      id 'h4'
      name 'h4'
      bold true
      size 32
    end

    @docx.style do
      id 'h5'
      name 'h5'
      bold true
      size 26
    end

    @docx.style do
      id 'h6'
      name 'h6'
      bold true
      size 24
    end

    @link_style = {
      color: '37a0d9',
      bold: true
    }

    @color = {
      gray: 'a0a0a0'
    }
  end

  def image_path(image)
    if image.is_stored_on_s3?
      image.url
    else
      image.open.path
    end
  end
end
