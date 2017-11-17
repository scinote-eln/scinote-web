module ProtocolsIoHelper
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

  def eval_prot_desc(text, attribute_name)
  case attribute_name
  when 'before_start'
    pio_eval_p_bfrandsafe_len(text)
  when 'warning'
    pio_eval_p_bfrandsafe_len(text)
  when 'guidelines'
    pio_eval_p_guid_len(text)
  when 'publish_date'
    pio_eval_p_pbldate_len(text)
  when 'vendor_name'
    pio_eval_p_misc_vnd_link_len(text)
  when 'vendor_link'
    pio_eval_p_misc_vnd_link_len(text)
  when 'keywords'
    pio_eval_p_keywords_tags_len(text)
  when 'link'
    pio_eval_p_misc_vnd_link_len(text)
  else
    ''
  end
    # ( before_start warning guidelines publish_date
    # vendor_name vendor_link keywords link )
  end

  def pio_eval_title_len(tekst)
    tekst += ' ' if tekst.length <= 1
    if tekst.length > 250
      tekst = tekst[0..195] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end
  # I put .length - number there instead of just adding it to right number
  # so that later if i need to change this implementation, i can use it as
  # a refference to what will always be allowed and where it can get cut
  # (in pio_eval_p_desc_len, it could get cut from indexes 4000 to 10000)

  # These can easily be adjusted if more room for an attribute is needed.
  # (Subtract from one, add to another)
  def pio_eval_p_desc_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.26
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_p_guid_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.24
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_p_bfrandsafe_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.18
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  # I am almost certain the 2 methods below this comment will never get called
  # But just incase someon adds huge urls or weird date format, i added them
  def pio_eval_p_misc_vnd_link_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.015
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_p_pbldate_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.0025
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end]
      @toolong = true
    end
    tekst
  end

  def pio_eval_p_keywords_tags_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.02
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_s_desc_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.48
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_s_cmd_desc_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.07
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_s_cmd_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.08
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_s_safe_expctres_len(tekst)
    max = 10000
    allowed_max_attr = max * 0.14
    text_end = allowed_max_attr - 60
    if tekst.length > allowed_max_attr
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end
end
