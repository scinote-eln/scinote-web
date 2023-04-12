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
    I18n.t('protocols.protocols_io_import.title_too_long').length + 5
  PIO_STEP_TOOLONG_LEN =
    I18n.t('protocols.protocols_io_import.too_long').length
  # The + 2 above (in title) is there because if the length was at the limit,
  # the cutter method had issues, this gives it some space

  # below are default min table settings (minimum 5x5)
  PIO_TABLE_MIN_WIDTH = 5
  PIO_TABLE_MIN_HEIGHT = 5

  def protocolsio_string_to_table_element(description_string)
    string_without_tables = string_html_table_remove(description_string)
    table_regex = %r{<table\b[^>]*>(.*?)<\/table>}m
    tr_regex = %r{<tr\b[^>]*>(.*?)<\/tr>}m
    td_regex = %r{<td\b[^>]*>(.*?)<\/td>}m
    tables = {}
    description_string.gsub! '<th>', '<td>'
    description_string.gsub! '</th>', '</td>'
    table_strings = description_string.scan(table_regex)
    table_strings.each_with_index do |table, table_counter|
      tables[table_counter.to_s] = {}
      tr_number = table[0].scan(tr_regex).count
      diff = PIO_TABLE_MIN_HEIGHT - tr_number # always tables have atleast 5 row
      table_fix_str = table[0]
      table_fix_str += '<tr></tr>' * diff if tr_number < PIO_TABLE_MIN_HEIGHT
      tr_strings = table_fix_str.scan(tr_regex)
      contents = {}
      contents['data'] = []
      tr_strings.each_with_index do |tr, tr_counter|
        td_strings = tr[0].scan(td_regex)
        contents['data'][tr_counter] = []
        td_counter = td_strings.count
        diff = PIO_TABLE_MIN_WIDTH - td_counter
        td_strings.each do |td|
          td_stripped = ActionController::Base.helpers.strip_tags(td[0])
          contents['data'][tr_counter].push(td_stripped)
        end
        next if td_counter >= PIO_TABLE_MIN_WIDTH
        diff.times { contents['data'][tr_counter].push(' ') }
      end
      tables[table_counter.to_s]['contents'] = Base64.encode64(
        contents.to_s.sub('=>', ':')
      )
      tables[table_counter.to_s]['name'] = ' '
    end
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
    when 'published_on'
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
    else
      ''
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
    else
      ''
    end
  end

  def pio_eval_authors(text)
    # Extract authors names from the JSON
    text.map { |auth| auth['name'] }.join(', ')
  rescue StandardError
    []
  end

  def eval_last_modified(steps)
    timestamps = steps.map do |step|
      step['modified_on'] if step['modified_on'].present?
    end
    I18n.l(Time.at(timestamps.max), format: :full)
  rescue StandardError
    I18n.l(Time.at(0), format: :full)
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

  def step_hash_null?(step_json)
    step_json.dig(
      0, 'components', 0, 'type_id'
    ).nil? && step_json.dig(
      0, 'components', '0', 'type_id'
    ).nil?
  end

  # Images are allowed in:
  # Step: description, expected result
  # Protocol description : description before_start warning
  # guidelines manuscript_citation

  def prepare_for_view(
    attribute_text1, size, table = 'no_table', image_allowed = false
  )
    image_tag = image_allowed ? Array('img') : Array(nil)
    image_tag.push('br')
    if table == 'no_table'
      attribute_text = sanitize_input(not_null(attribute_text1), image_tag)
    elsif table == 'table'
      attribute_text = sanitize_input(
        string_html_table_remove(not_null(attribute_text1)), image_tag
      )
    end
    pio_eval_len(
      attribute_text,
      size
    )
  end

  def fill_attributes(attribute_name, attribute_text, step_component)
    output_string = ''
    trans_string = step_component
    trans_string +=
      if attribute_name != 'os_name' && attribute_name != 'os_version'
        attribute_name
      else
        'os'
      end
    output_string +=
      if attribute_name != 'os_version'
        t(trans_string)
      else
        ' , '
      end
    if attribute_name == 'protocol_name'
      output_string += pio_eval_title_len(attribute_text)
    else
      output_string += prepare_for_view(
        attribute_text, ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
      )
    end
    output_string
  end

  # pio_stp_x means protocols io step (id of component) parser
  # protocols io description parser
  def pio_stp_1(iterating_key)
    br = '<br>'
    append =
      if iterating_key.present?
        br +
        prepare_for_view(
          iterating_key,
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL,
          'table',
          true
          ) +
        br
      else
        t('protocols.protocols_io_import.comp_append.missing_desc')
      end
    append
  end

  def pio_stp_6(iterating_key)
    if iterating_key.present?
      # protocols io section(title) parser
      return pio_eval_title_len(CGI.unescapeHTML(sanitize_input(iterating_key)))
    end
    t('protocols.protocols_io_import.comp_append.missing_step')
  end

  def pio_stp_17(iterating_key)
    # protocols io expected result parser
    if iterating_key.present?
      append =
        t('protocols.protocols_io_import.comp_append.expected_result') +
        prepare_for_view(
          iterating_key,
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL,
          'table',
          true
        ) +
        '<br>'
      return append
    end
    ''
  end
  # protocols io software package,dataset,commands,
  # sub_protocol and safety_information  parser

  def pio_stp(iterating_key, parse_elements_array, en_local_text)
    append = ''
    parse_elements_array.each do |element|
      next unless iterating_key[element]
      append += fill_attributes(
        element,
        iterating_key[element],
        en_local_text
      )
    end
    append
  end

  def protocols_io_fill_desc(json_hash)
    unshortened_string_for_tables = ''
    description_array = %w[
      ( before_start warning guidelines manuscript_citation published_on
      vendor_name vendor_link keywords tags link created_on )
    ]
    allowed_image_attributes = %w[
      ( before_start warning guidelines manuscript_citation )
    ]
    if json_hash['description'].present?
      unshortened_string_for_tables += json_hash['description']
      description_string =
        '<strong>' +
        t('protocols.protocols_io_import.preview.description') +
        '</strong>' +
        prepare_for_view(
          json_hash['description'],
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM,
          'table',
          true
        ).html_safe
    else
      description_string =
        '<strong>' +
        t('protocols.protocols_io_import.preview.description') +
        '</strong>' +
        t('protocols.protocols_io_import.comp_append.missing_desc')
    end
    description_string += '<br>'
    description_array.each do |e|
      if e == 'created_on' && json_hash[e].present?
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ':  ' +
          prepare_for_view(
            params['protocol']['created_at'].to_s,
            ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL
          ) +
          + '<br>'
      elsif e == 'tags' && json_hash[e].present? \
            && json_hash[e].any? && json_hash[e] != ''
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ': '
        tags_length_checker = ''
        json_hash[e].each do |tag|
          tags_length_checker +=
            sanitize_input(tag['tag_name']) + ' , '
        end
        description_string += prepare_for_view(
          tags_length_checker,
          ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM
        )
        description_string += '<br>'
      elsif json_hash[e].present?
        data =
          if e == 'published_on'
            Time.at(json_hash[e]).utc.to_datetime.to_s
          else
            json_hash[e]
          end
        unshortened_string_for_tables += data
        new_e = '<strong>' + e.humanize + '</strong>'
        image_tag = allowed_image_attributes.include?(e) ? Array('img') : Array(nil)
        description_string +=
          new_e.to_s + ':  ' + # intercept tables here, before cut
          pio_eval_prot_desc(
            sanitize_input(data, image_tag),
            e
          ).html_safe + '<br>'
      end
    end
    return description_string, unshortened_string_for_tables
  end

  def protocols_io_guid_reorder_step_json(unordered_step_json)
    return '' if unordered_step_json.blank?
    base_step = unordered_step_json.find { |step| step['previous_guid'].nil? }
    return unordered_step_json if base_step.nil?
    number_of_steps = unordered_step_json.size
    return unordered_step_json if number_of_steps == 1
    step_order = []
    step_counter = 0
    step_order[step_counter] = base_step
    step_counter += 1
    while step_order.length != number_of_steps
      step_order[step_counter] =
        unordered_step_json.find do |step|
          step['previous_guid'] == base_step['guid']
        end
      base_step = step_order[step_counter]
      step_counter += 1
    end
    step_order
  end

  def protocols_io_fill_step(original_json, newj)
    # newj = new json
    # (simple to map) id 1= step description, id 6= section (title),
    # id 17= expected result
    # (complex mapping with nested hashes) id 8 = software package,
    # id 9 = dataset, id 15 = command, id 18 = attached sub protocol
    # id 19= safety information ,
    # id 20= regents (materials, like scinote inventories kind of)

    original_json['steps'] = protocols_io_guid_reorder_step_json(
      original_json['steps']
    )
    newj['0'] = {}
    newj['0']['position'] = 0
    newj['0']['name'] = 'Protocol info'
    @remaining = ProtocolsIoHelper::PIO_P_AVAILABLE_LENGTH
    shortened_string, unshortened_tables_string = protocols_io_fill_desc(
      original_json
    )
    newj['0']['tables'] = protocolsio_string_to_table_element(
      sanitize_input(unshortened_tables_string)
    )[0]
    table_str = protocolsio_string_to_table_element(
      sanitize_input(shortened_string, Array('img'))
    )[1]
    newj['0']['description'] = table_str
    original_json['steps'].each_with_index do |step, pos_orig| # loop over steps
      i = pos_orig + 1
      @remaining = ProtocolsIoHelper::PIO_S_AVAILABLE_LENGTH
      # position of step (first, second.... etc),
      newj[i.to_s] = {} # the json we will insert into db
      newj[i.to_s]['position'] = i
      newj[i.to_s]['description'] = '' unless newj[i.to_s].key?('description')
      newj[i.to_s]['name'] = '' unless newj[i.to_s].key?('name')
      unshortened_step_table_string = ''
      step['components'].each do |key, value|
        # sometimes there are random index values as keys
        # instead of hashes, this is a workaround to that buggy json format
        key = value if value.class == Hash
        # append is the string that we append values into for description
        # pio_stp_x means protocols io step (id of component) parser
        case key['type_id']
        # intercept tables in all of below before cutting
        when 1
          unshortened_step_table_string += key['source']['description']
          newj[i.to_s]['description'] += pio_stp_1(key['source']['description'])
        when 6
          newj[i.to_s]['name'] = pio_stp_6(key['source']['title'])
        when 17
          unshortened_step_table_string += key['source']['body']
          newj[i.to_s]['description'] += pio_stp_17(key['source']['body'])
        when 8
          pe_array = %w(
            name developer version link repository os_name os_version
          )
          trans_text = 'protocols.protocols_io_import.comp_append.soft_packg.'
          newj[i.to_s]['description'] += pio_stp(
            key['source'], pe_array, trans_text
          )
        when 9
          pe_array = %w(
            name link
          )
          trans_text = 'protocols.protocols_io_import.comp_append.dataset.'
          newj[i.to_s]['description'] += pio_stp(
            key['source'], pe_array, trans_text
          )
        when 15
          pe_array = %w(
            name description os_name os_version
          )
          key['source']['name'] =
            '<pre><code>' +
            not_null(key['source']['name'].gsub(/\n/, '<br>')) +
            '</code></pre>'
          trans_text = 'protocols.protocols_io_import.comp_append.command.'
          newj[i.to_s]['description'] += pio_stp(
            key['source'], pe_array, trans_text
          )
        when 18
          pe_array = %w(
            title title_html uri
          )
          trans_text = 'protocols.protocols_io_import.comp_append.sub_protocol.'
          newj[i.to_s]['description'] += pio_stp(
            key['source'], pe_array, trans_text
          )
        when 19
          pe_array = %w(
            body link
          )
          trans_text = 'protocols.protocols_io_import.comp_append.safety_infor.'
          newj[i.to_s]['description'] += pio_stp(
            key['source'], pe_array, trans_text
          )
        end # case end
      end # finished looping over step components
      table_str = protocolsio_string_to_table_element(
        newj[i.to_s]['description']
      )[1]
      newj[i.to_s]['description'] = table_str
      newj[i.to_s]['tables'] = protocolsio_string_to_table_element(
        sanitize_input(unshortened_step_table_string)
      )[0]
    end # steps
    newj
  end

  def get_steps(json)
    # Get steps of the given json_object
    if json.key?('steps') && json['steps'].respond_to?('each')
      json['steps']
    else
      []
    end
  end

  def get_components(step_json)
    # Get components of given step_json
    if step_json.key?('components') &&
       step_json['components'].respond_to?('each')
      step_json['components']
    else
      []
    end
  end
end
