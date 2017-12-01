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
    PIO_ELEMENT_RESERVED_LENGTH_BIG * 2)
  # -- 2 small = created at , publish date PROTOCOL ATTRIBUTES
  # -- 8 medium = description,tags,before_start,warning,guidelines,
  # manuscript_citation,keywords,vendor_name PROTOCOL ATTRIBUTES
  # -- 2 big = vendor_link, link PROTOCOL ATTRIBUTES

  # PROTOCOLS.IO STEP ATTRIBUTES
  PIO_S_AVAILABLE_LENGTH =
    TEXT_MAX_LENGTH -
    (PIO_ELEMENT_RESERVED_LENGTH_SMALL * 20)
  # -- 20 small = description,expected_result,safety_information
  # software_package version, software_package os_name,
  # software_package os_version,software_package link,
  # software_package repository,software_package developer,software_package name
  # commands os_version,commands os_name, commands name,commands description,
  # sub protocol full name (author), sub protocol name, sub protocol link,
  # dataset link,dataset name, safety_information link,
  # -- 0 medium =
  # -- 0 big =

  PIO_TITLE_TOOLONG_LEN =
    I18n.t('protocols.protocols_io_import.title_too_long').length + 2
  PIO_STEP_TOOLONG_LEN =
    I18n.t('protocols.protocols_io_import.too_long').length
  # The + 2 above (in title) is there because if the length was at the limit,
  # the cutter method had issues, this gives it some space
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
    when 'vendor_link', 'link'
      pio_eval_len(text, ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_BIG)
    else
      pio_eval_len(text, ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM)
    end
  end

  def pio_eval_title_len(text)
    if text
      text += ' ' if text.length < Constants::NAME_MIN_LENGTH
      if text.length > Constants::NAME_MAX_LENGTH
        text =
          text[0..(Constants::NAME_MAX_LENGTH - PIO_TITLE_TOOLONG_LEN)] +
          t('protocols.protocols_io_import.title_too_long')
        @toolong = true
      end
      text
    end
  end

  def pio_eval_len(text, reserved)
    if text
      text_end = reserved + @remaining - PIO_STEP_TOOLONG_LEN
      text_end = 2 if text_end < 2
      # Since steps have very low reserved values now (below 100),
      # the above sets their index to 1 if its negative
      # (length of toolong text is about 90 chars, and if remaining is 0,
      # then the negative index just gets set to 1. this is a workaround

      # it would also be possible to not count the length of the "too long" text
      # or setting the import reserved value to 95,but then available characters
      # will be like before (around 7600)
      if text.length - reserved > @remaining
        text =
          close_open_html_tags(
            text[0..text_end] + t('protocols.protocols_io_import.too_long')
          )
        @toolong = true
        @remaining = 0
      elsif (text.length - reserved) > 0
        @remaining -= text.length - reserved
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

  def prepare_for_view(attribute_text, size)
    case(size)
    when 'small'
      pio_eval_len(
        sanitize_input(string_html_table_remove(not_null(attribute_text))),
        ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
      )
    when 'medium'
      pio_eval_len(
        sanitize_input(string_html_table_remove(not_null(attribute_text))),
        ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM
      )
    when 'big'
      pio_eval_len(
        sanitize_input(string_html_table_remove(not_null(attribute_text))),
        ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_BIG
      )
    else
    end
  end

  # pio_stp_x means protocols io step (id of component) parser
  def pio_stp_1(iterating_key) # protocols io description parser
    br = '<br>'
    append =
      if iterating_key.present?
        br +
        pio_eval_len(
          sanitize_input(iterating_key),
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
        ) +
        br
      else
        t('protocols.protocols_io_import.comp_append.missing_desc')
      end
    append
  end

  def pio_stp_6(iterating_key) # protocols io section(title) parser
    return pio_eval_title_len(sanitize_input(iterating_key)) if iterating_key.present?
    t('protocols.protocols_io_import.comp_append.missing_step')
  end

  def pio_stp_17(iterating_key) # protocols io expected result parser
    if iterating_key.present?
      append =
        t('protocols.protocols_io_import.comp_append.expected_result') +
        pio_eval_len(
          sanitize_input(iterating_key),
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
        ) +
        '<br>'
      return append
    end
    ''
  end

  def pio_stp_8(iterating_key) # protocols io software package parser
    if iterating_key['name'] &&
       iterating_key['developer'] &&
       iterating_key['version'] &&
       iterating_key['link'] &&
       iterating_key['repository'] &&
       iterating_key['os_name'] &&
       iterating_key['os_version']
      append = t('protocols.protocols_io_import.comp_append.soft_packg.title') +
               pio_eval_len(
                 sanitize_input(iterating_key['name']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.soft_packg.dev') +
               pio_eval_len(
                 sanitize_input(iterating_key['developer']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.soft_packg.vers') +
               pio_eval_len(
                 sanitize_input(iterating_key['version']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.general_link') +
               pio_eval_len(
                 sanitize_input(iterating_key['link']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.soft_packg.repo') +
               pio_eval_len(
                 sanitize_input(iterating_key['repository']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.soft_packg.os') +
               pio_eval_len(
                 sanitize_input(iterating_key['os_name']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) + ' , ' +
               pio_eval_len(
                 sanitize_input(iterating_key['os_version']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               )
      return append
    end
    ''
  end

  def pio_stp_9(iterating_key) # protocols io dataset parser
    if iterating_key['name'].present? &&
       iterating_key['link']
      append = t('protocols.protocols_io_import.comp_append.dataset.title') +
               pio_eval_len(
                 sanitize_input(iterating_key['name']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.general_link') +
               pio_eval_len(
                 sanitize_input(iterating_key['link']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               )
      return append
    end
    ''
  end

  def pio_stp_15(iterating_key) # protocols io commands parser
    if iterating_key['name'].present? &&
       iterating_key['description'] &&
       iterating_key['os_name'] &&
       iterating_key['os_version']
      append = t('protocols.protocols_io_import.comp_append.command.title') +
               pio_eval_len(
                 sanitize_input(iterating_key['name']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.command.desc') +
               pio_eval_len(
                 sanitize_input(iterating_key['description']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               t('protocols.protocols_io_import.comp_append.command.os') +
               pio_eval_len(
                 sanitize_input(iterating_key['os_name']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               ) +
               ' , ' +
               pio_eval_len(
                 sanitize_input(iterating_key['os_version']),
                 ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
               )
      return append
    end
    ''
  end

  def pio_stp_18(iterating_key) # protocols io sub protocol parser
    if iterating_key['protocol_name'].present? &&
       iterating_key['full_name'] &&
       iterating_key['link']
      append =
        t(
          'protocols.protocols_io_import.comp_append.sub_protocol.title'
        ) +
        pio_eval_len(
          sanitize_input(iterating_key['protocol_name']),
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
        ) +
        t(
          'protocols.protocols_io_import.comp_append.sub_protocol.author'
        ) +
        pio_eval_len(
          sanitize_input(iterating_key['full_name']),
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
        ) +
        t('protocols.protocols_io_import.comp_append.general_link') +
        pio_eval_len(
          sanitize_input(iterating_key['link']),
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
        )
      return append
    end
    ''
  end

  def pio_stp_19(iterating_key) # protocols io safety information parser
    if iterating_key['body'].present? &&
       iterating_key['link']
      append =
        t(
          'protocols.protocols_io_import.comp_append.safety_infor.title'
        ) +
        pio_eval_len(
          sanitize_input(iterating_key['body']),
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
        ) +
        t('protocols.protocols_io_import.comp_append.general_link') +
        pio_eval_len(
          sanitize_input(iterating_key['link']),
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
        )
      return append
    end
    ''
  end

  def protocols_io_fill_desc(json_hash)
    description_array = %w[
      ( before_start warning guidelines manuscript_citation publish_date
      vendor_name vendor_link keywords tags link created_on )
    ]
    description_string =
      if json_hash['description'].present?
        '<strong>' + t('protocols.protocols_io_import.preview.prot_desc') +
          '</strong>' + pio_eval_len(
            sanitize_input(json_hash['description']),
            ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM
          ).html_safe
      else
        '<strong>' + t('protocols.protocols_io_import.preview.prot_desc') +
          '</strong>' + t('protocols.protocols_io_import.comp_append.missing_desc')
      end
    description_string += '<br>'
    description_array.each do |e|
      if e == 'created_on' && json_hash[e].present?
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ':  ' + pio_eval_len(
            sanitize_input(params['protocol']['created_at'].to_s),
            ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
          ) + '<br>'
      elsif e == 'tags' && json_hash[e].any? && json_hash[e] != ''
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ': '
        tags_length_checker = ''
        json_hash[e].each do |tag|
          tags_length_checker +=
            sanitize_input(tag['tag_name']) + ' , '
        end
        description_string += pio_eval_len(
          tags_length_checker,
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM
        )
        description_string += '<br>'
      elsif json_hash[e].present?
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ':  ' +
          pio_eval_prot_desc(
            sanitize_input(json_hash[e]),
            e
          ).html_safe + '<br>'
      end
    end
    description_string
  end

  def protocols_io_fill_step(original_json, newj)
    # newj = new json
    # (simple to map) id 1= step description, id 6= section (title),
    # id 17= expected result
    # (complex mapping with nested hashes) id 8 = software package,
    # id 9 = dataset, id 15 = command, id 18 = attached sub protocol
    # id 19= safety information ,
    # id 20= regents (materials, like scinote samples kind of)
    newj['0'] = {}
    newj['0']['position'] = 0
    newj['0']['name'] = 'Protocol info'
    @remaining = ProtocolsIoHelper::PIO_P_AVAILABLE_LENGTH
    newj['0']['tables'], table_str = protocolsio_string_to_table_element(
      sanitize_input(protocols_io_fill_desc(original_json).html_safe)
    )
    newj['0']['description'] = table_str
    original_json['steps'].each_with_index do |step, pos_orig| # loop over steps
      i = pos_orig + 1
      @remaining = ProtocolsIoHelper::PIO_S_AVAILABLE_LENGTH
      # position of step (first, second.... etc),
      newj[i.to_s] = {} # the json we will insert into db
      newj[i.to_s]['position'] = i
      newj[i.to_s]['description'] = '' unless newj[i.to_s].key?('description')
      newj[i.to_s]['name'] = '' unless newj[i.to_s].key?('name')
      step['components'].each do |key, value|
        # sometimes there are random index values as keys
        # instead of hashes, this is a workaround to that buggy json format
        key = value if value.class == Hash
        # append is the string that we append values into for description
        # pio_stp_x means protocols io step (id of component) parser
        case key['component_type_id']
        when '1'
          newj[i.to_s]['description'] += pio_stp_1(key['data'])
        when '6'
          newj[i.to_s]['name'] = pio_stp_6(key['data'])
        when '17'
          newj[i.to_s]['description'] += pio_stp_17(key['data'])
        when '8'
          newj[i.to_s]['description'] += pio_stp_8(key['source_data'])
        when '9'
          newj[i.to_s]['description'] += pio_stp_9(key['source_data'])
        when '15'
          newj[i.to_s]['description'] += pio_stp_15(key['source_data'])
        when '18'
          newj[i.to_s]['description'] += pio_stp_18(key['source_data'])
        when '19'
          newj[i.to_s]['description'] += pio_stp_19(key['source_data'])
        end # case end
      end # finished looping over step components
      newj[i.to_s]['tables'], table_str = protocolsio_string_to_table_element(
        newj[i.to_s]['description']
      )
      newj[i.to_s]['description'] = table_str
    end # steps
    newj
  end

end
