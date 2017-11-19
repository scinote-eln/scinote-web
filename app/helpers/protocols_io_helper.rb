module ProtocolsIoHelper
  #=============================================================================
  # Protocols.io limits
  #=============================================================================
  TEXT_MAX_LENGTH = Constants::TEXT_MAX_LENGTH
  # PROTOCOLS.IO PROTOCOL ATTRIBUTES

  # Protocols io protocol description reserved length
  PIO_P_DESC_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.06
  # Protocols io protocol guidelines attribute reserved length
  PIO_P_GUIDELINES_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.04
  # Protocols io protocol before starting attribute reserved length
  PIO_P_BEFORESTART_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.04
  # Protocols io protocol safety warnings attribute reserved length
  PIO_P_SAFETYWARNING_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.04
  # Protocols io protocol manuscript citation attribute reserved length
  PIO_P_MANUCIT_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.04
  # Protocols io protocol keywords attribute reserved length
  PIO_P_KEYWORDS_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.02
  # Protocols io protocol tags attribute reserved length
  PIO_P_TAGS_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.02
  # Protocols io protocol vendor link attribute reserved length
  PIO_P_VNDLINK_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.05
  # Protocols io protocol external link attribute reserved length
  PIO_P_EXTLINK_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.05
  # Protocols io protocol vendor name attribute reserved length
  PIO_P_VNDNAME_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.015
  # Protocols io protocol publish date attribute reserved length
  PIO_P_PBLDATE_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.005
  # Protocols io protocol created on date attribute reserved length
  PIO_P_CREATEDON_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.005

  # Total reserved percent for protocol desc:
  # 39% (actual 38.5%) + 4%(400) (actual 388) extra = 43% reserved
  # PROTOCOLS.IO STEP ATTRIBUTES

  # Protocols io step PIO_S_DESC_RESERVED_LENGTH attribute reserve
  PIO_S_DESC_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.08

  # Protocols io step PIO_S_SOFT_NAME_RESERVED_LENGTH attribute reserve
  PIO_S_SOFT_NAME_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0064
  # Protocols io step PIO_S_SOFT_DEVELOPER_RESERVED_LENGTH attribute reserve
  PIO_S_SOFT_DEV_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0128
  # Protocols io step PIO_S_SOFT_VERSION_RESERVED_LENGTH attribute reserve
  PIO_S_SOFT_VERSION_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0016
  # Protocols io step PIO_S_SOFT_LINK_RESERVED_LENGTH attribute reserve
  PIO_S_SOFT_LINK_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0512
  # Protocols io step PIO_S_SOFT_REPLINK_RESERVED_LENGTH attribute reserve
  PIO_S_SOFT_REPLINK_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0512
  # Protocols io step PIO_S_SOFT_OSNAME_RESERVED_LENGTH attribute reserve
  PIO_S_SOFT_OSNAME_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0128
  # Protocols io step PIO_S_SOFT_OSVERSION_RESERVED_LENGTH attribute reserve
  PIO_S_SOFT_OSVERSION_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0032

  # Protocols io step PIO_S_DATA_NAME_RESERVED_LENGTH attribute reserve
  PIO_S_DATA_NAME_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0064
  # Protocols io step PIO_S_DATA_LINK_RESERVED_LENGTH attribute reserve
  PIO_S_DATA_LINK_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0512

  # Protocols io step PIO_S_COM_OSNAME_RESERVED_LENGTH attribute reserve
  PIO_S_COM_OSNAME_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0128
  # Protocols io step PIO_S_COM_OSVERSION_RESERVED_LENGTH attribute reserve
  PIO_S_COM_OSVERSION_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0032
  # Protocols io step PIO_S_COM_DESCRIPTION_RESERVED_LENGTH attribute reserve
  PIO_S_COM_DESCRIPTION_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0200
  # Protocols io step PIO_S_COM_COMMAND_RESERVED_LENGTH attribute reserve
  PIO_S_COM_COMMAND_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0200

  # Protocols io step PIO_S_SUBPROT_AUTHOR_RESERVED_LENGTH attribute reserve
  PIO_S_SUBPROT_AUTHOR_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0128
  # Protocols io step PIO_S_SUBPROT_NAME_RESERVED_LENGTH attribute reserve
  PIO_S_SUBPROT_NAME_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0256
  # Protocols io step PIO_S_SUBPROT_LINK_RESERVED_LENGTH attribute reserve
  PIO_S_SUBPROT_LINK_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0512

  # Protocols io step PIO_S_SAFETY_INFO_RESERVED_LENGTH attribute reserve
  PIO_S_SAFETY_INFO_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0400
  # Protocols io step PIO_S_SAFETY_LINK_RESERVED_LENGTH attribute reserve
  PIO_S_SAFETY_LINK_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0512

  # Protocols io step PIO_S_EXPECTEDRESULT_RESERVED_LENGTH attribute reserve
  PIO_S_EXPECTEDRESULT_RESERVED_LENGTH = TEXT_MAX_LENGTH * 0.0400

  # Total reserved percent for step desc:
  # 56% (actual 55.36%) + 5.5%(550) (actual 548) = 61.5% reserved

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
    when 'before_start'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_BEFORESTART_RESERVED_LENGTH)
    when 'warning'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_SAFETYWARNING_RESERVED_LENGTH)
    when 'guidelines'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_GUIDELINES_RESERVED_LENGTH)
    when 'publish_date'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_PBLDATE_RESERVED_LENGTH)
    when 'vendor_name'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_VNDNAME_RESERVED_LENGTH)
    when 'vendor_link'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_VNDLINK_RESERVED_LENGTH)
    when 'keywords'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_KEYWORDS_RESERVED_LENGTH)
    when 'link'
      pio_eval_len(text, ProtocolsIoHelper::PIO_P_EXTLINK_RESERVED_LENGTH)
    else
      ''
    end
  end

  def pio_eval_title_len(tekst)
    tekst += ' ' if tekst.length < Constants::NAME_MIN_LENGTH
    if tekst.length > Constants::NAME_MAX_LENGTH
      tekst = tekst[0..(Constants::NAME_MAX_LENGTH - 60)] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    tekst
  end

  def pio_eval_len(tekst, reserved)
    text_end = reserved + @remaining - 60
    if tekst.length - reserved > @remaining
      tekst = tekst[0..text_end] + t('protocols.protocols_io_import.too_long')
      @toolong = true
    end
    @remaining -= (tekst.length - reserved)
    tekst
  end
end
