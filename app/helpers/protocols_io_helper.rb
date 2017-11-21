module ProtocolsIoHelper
  #=============================================================================
  # Protocols.io limits
  #=============================================================================
  TEXT_MAX_LENGTH = Constants::TEXT_MAX_LENGTH

  PIO_ELEMENT_RESERVED_LENGTH_BIG = TEXT_MAX_LENGTH * 0.015
  PIO_ELEMENT_RESERVED_LENGTH_MEDIUM = TEXT_MAX_LENGTH * 0.01
  PIO_ELEMENT_RESERVED_LENGTH_SMALL = TEXT_MAX_LENGTH * 0.005

  # PROTOCOLS.IO PROTOCOL ATTRIBUTES
  PIO_P_AVAILABLE_LENGTH =
    TEXT_MAX_LENGTH -
    (PIO_ELEMENT_RESERVED_LENGTH_SMALL * 2 +
    PIO_ELEMENT_RESERVED_LENGTH_MEDIUM * 8 +
    PIO_ELEMENT_RESERVED_LENGTH_BIG * 2 +
    400)
  # 400 is for en.yml text

  # PROTOCOLS.IO STEP ATTRIBUTES
  PIO_S_AVAILABLE_LENGTH =
    TEXT_MAX_LENGTH -
    (PIO_ELEMENT_RESERVED_LENGTH_SMALL * 4 +
    PIO_ELEMENT_RESERVED_LENGTH_MEDIUM * 11 +
    PIO_ELEMENT_RESERVED_LENGTH_BIG * 5 +
    550)
  # 550 reserved for en.yml translations

  PIO_TITLE_TOOLONG_LEN =
    I18n.t('protocols.protocols_io_import.title_too_long').length + 5
  PIO_STEP_TOOLONG_LEN =
    I18n.t('protocols.protocols_io_import.too_long').length + 5
  def protocolsio_string_to_table_element(description_string)
    string_without_tables = string_html_table_remove(description_string)
    table_regex = %r{<table\b[^>]*>(.*?)<\/table>}m
    tr_regex = %r{<tr\b[^>]*>(.*?)<\/tr>}m
    td_regex = %r{<td\b[^>]*>(.*?)<\/td>}m
    tables = {}
    table_strings = description_string.scan(table_regex)
    table_strings.each_with_index do |table, table_counter|
      tables[table_counter.to_s] = {}
      tr_strings = table[0].scan(tr_regex)
      contents = {}
      contents['data'] = []
      tr_strings.each_with_index do |tr, tr_counter|
        td_strings = tr[0].scan(td_regex)
        contents['data'][tr_counter] = []
        td_strings.each do |td|
          td_stripped = ActionController::Base.helpers.strip_tags(td[0])
          contents['data'][tr_counter].push(td_stripped)
        end
      end
      tables[table_counter.to_s]['contents'] = Base64.encode64(
        contents.to_s.sub('=>', ':')
      )
      tables[table_counter.to_s]['name'] = nil
    end
    # return string_without_tables, tables
    return tables, string_without_tables
  end

  def string_html_table_remove(description_string)
    description_string.remove!("\n", "\t", "\r", "\f")
    table_whole_regex = %r{(<table\b[^>]*>.*?<\/table>)}m
    table_pattern_array = description_string.scan(table_whole_regex)
    string_without_tables = description_string
    table_pattern_array.each do |table_pattern|
      string_without_tables = string_without_tables.gsub(
        table_pattern[0],
        t('protocols.protocols_io_import.comp_append.table_moved').html_safe
      )
    end
    string_without_tables
  end

  def pio_eval_prot_desc(text, attribute_name)
    case attribute_name
    when 'publish_date'
      pio_eval_len(text, ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL)
    when 'vendor_link'
      pio_eval_len(text, ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_BIG)
    when 'link'
      pio_eval_len(text, ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_BIG)
    else
      pio_eval_len(text, ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM)
    end
  end

  def pio_eval_title_len(text)
    text += ' ' if text.length < Constants::NAME_MIN_LENGTH
    if text.length > Constants::NAME_MAX_LENGTH
      text =
        text[0..(Constants::NAME_MAX_LENGTH - PIO_TITLE_TOOLONG_LEN)] +
        t('protocols.protocols_io_import.title_too_long')
      @toolong = true
    end
    text
  end

  def pio_eval_len(text, reserved)
    if text
      text_end = reserved + @remaining - PIO_STEP_TOOLONG_LEN
      if text.length - reserved > @remaining
        text =
          close_open_html_tags(text[0..text_end]) +
          t('protocols.protocols_io_import.too_long')
        @toolong = true
        @remaining = 0
      else
        @remaining -= (text.length - reserved)
      end
      text
    end
  end

  # Checks so that null values are returned as zero length strings
  # Did this so views arent as ugly (i avoid using if present statements)
  def not_null(attribute)
    if attribute
      attribute
    else
      ''
    end
  end

  def close_open_html_tags(text)
    Nokogiri::HTML::DocumentFragment.parse(text).to_html
  end
end
