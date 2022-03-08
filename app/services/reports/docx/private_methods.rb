# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::PrivateMethods
  private

<<<<<<< HEAD
=======
module PrivateMethods
=======
module Reports::Docx::PrivateMethods
>>>>>>> Initial commit of 1.17.2 merge
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
                link_url = Reports::Docx.link_prepare(scinote_url, text_el[:link])
                link text_el[:value], link_url, link_style
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
        @docx.img elem[:data] do
          data elem[:blob].download
          width style[:width]
          height style[:height]
          align style[:align] || :left
        end
      end
    end
  end

  # Convert HTML structure to plain text structure
  def recursive_children(children, elements)
    children.each do |elem|
      if elem.class == Nokogiri::XML::Text
        next if elem.text.strip == ' ' # Invisible symbol

        style = paragraph_styling(elem.parent)
        type = (style[:align] && style[:align] != :justify) || style[:style] ? 'newline' : 'text'

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

      if elem.name == 'img' && elem.attributes['data-mce-token']

        image = TinyMceAsset.find_by(id: Base62.decode(elem.attributes['data-mce-token'].value))
        next unless image

        image_path = image_path(image.image)
        dimension = FastImage.size(image_path)
        style = image_styling(elem, dimension)

        elements.push(
          type: 'image',
          data: image_path.split('&')[0],
          blob: image.blob,
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
    style_keys = %w(text-align color)

    if style
      style_keys.each do |key|
        style_el = style.value.split(';').select { |i| (i.include? key) }[0]
        next unless style_el

        value = style_el.split(':')[1].strip if style_el
        if key == 'text-align'
          result[:align] = value.to_sym
        elsif key == 'color' && calculate_color_hsp(value) < 190
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
    return unless asset

    image_path = image_path(asset.file)

    dimension = FastImage.size(image_path)
    x = dimension[0]
    y = dimension[1]
    if x > 300
      y = y * 300 / x
      x = 300
    end
    @docx.img image_path.split('&')[0] do
      data asset.blob.download
      width x
      height y
    end
  end

>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Pulled latest release
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

<<<<<<< HEAD
<<<<<<< HEAD
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

=======
>>>>>>> Finished merging. Test on dev machine (iMac).
    generate_html_styles
  end

  def generate_html_styles
    @docx.style do
<<<<<<< HEAD
      id 'Heading1'
      name 'heading 1'
      font 'Arial'
      size 36
      bottom 120
      bold true
=======
      id 'h1'
      name 'h1'
      bold true
      size 64
=======
    path = Rails.root.join('app', 'assets', 'images', 'logo.png')

    @docx.img path.to_s do
      height 20
      width 100
      align :left
>>>>>>> Pulled latest release
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
<<<<<<< HEAD
      size 24
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Pulled latest release
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
<<<<<<< HEAD
<<<<<<< HEAD
=======

  def image_path(attachment)
    attachment.service_url
  end

  def calculate_color_hsp(color)
    return 255 if color.length != 7

    color = color.delete('#').scan(/.{1,2}/)
    rgb = color.map(&:hex)
    Math.sqrt(
      0.299 * (rgb[0]**2) +
      0.587 * (rgb[1]**2) +
      0.114 * (rgb[2]**2)
    )
  end
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Pulled latest release
end
