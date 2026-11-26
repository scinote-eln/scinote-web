# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsIoHelper, type: :helper do
  let(:i18n) { 'protocols.protocols_io_import' }
  let(:too_long) { I18n.t("#{i18n}.too_long") }
  let(:reserved_small) { ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL }

  def remaining(value)
    helper.instance_variable_set(:@remaining, value)
  end

  # JSON parsed payloads (as received from protocols.io) hold unfrozen strings
  def thaw(object)
    JSON.parse(object.to_json)
  end

  def decode_table(table)
    Base64.decode64(table['contents'])
  end

  describe '#protocolsio_string_to_table_element' do
    let(:html) do
      +'before<table><tr><th>H1</th><th>H2</th></tr><tr><td>a</td><td><b>b</b></td></tr></table>after'
    end

    it 'converts html tables to padded 5x5 table elements and replaces them in the text' do
      tables, text = helper.protocolsio_string_to_table_element(html)
      contents = decode_table(tables['0'])

      expect(tables.keys).to eq ['0']
      expect(tables['0']['name']).to eq ' '
      expect(contents).to include('"H1"', '"H2"', '"a"', '"b"')
      expect(contents).not_to include('<b>')
      expect(contents.scan('[').size).to eq 6 # outer array + 5 rows
      expect(text).to start_with('before')
      expect(text).to end_with('after')
      expect(text).not_to include('<table')
      expect(text).to include(I18n.t("#{i18n}.comp_append.table_moved"))
    end

    it 'returns no tables for text without tables' do
      tables, text = helper.protocolsio_string_to_table_element(+'plain')

      expect(tables).to eq({})
      expect(text).to eq 'plain'
    end

    it 'does not pad rows that are wider than the minimum width' do
      wide = +"<table>#{'<tr>' + ('<td>x</td>' * 6) + '</tr>' * 1}#{'<tr><td>y</td></tr>' * 4}</table>"
      tables, = helper.protocolsio_string_to_table_element(wide)

      expect(decode_table(tables['0']).scan('"x"').size).to eq 6
    end
  end

  describe '#string_html_table_remove' do
    it 'strips whitespace control characters and replaces tables' do
      result = helper.string_html_table_remove(+"a\n\tb<table><tr><td>1</td></tr></table>c\r")

      expect(result).to eq "ab#{I18n.t("#{i18n}.comp_append.table_moved")}c"
    end
  end

  describe '#pio_eval_title_len' do
    it 'returns an empty string for nil' do
      expect(helper.pio_eval_title_len(nil)).to eq ''
    end

    it 'pads titles shorter than the minimum length' do
      expect(helper.pio_eval_title_len('a')).to eq 'a '
    end

    it 'keeps valid titles untouched' do
      expect(helper.pio_eval_title_len('Valid title')).to eq 'Valid title'
      expect(helper.instance_variable_get(:@toolong)).to be_nil
    end

    it 'shortens too long titles and flags them' do
      result = helper.pio_eval_title_len('x' * 400)

      expect(result.length).to be <= Constants::NAME_MAX_LENGTH
      expect(result).to end_with(I18n.t("#{i18n}.title_too_long"))
      expect(helper.instance_variable_get(:@toolong)).to be true
    end
  end

  describe '#pio_eval_len' do
    it 'returns an empty string for nil' do
      expect(helper.pio_eval_len(nil, 10)).to eq ''
    end

    it 'decreases the remaining budget by the text length above the reserve' do
      remaining(1000)

      expect(helper.pio_eval_len('a' * 100, 40)).to eq 'a' * 100
      expect(helper.instance_variable_get(:@remaining)).to eq 940
    end

    it 'does not change the budget when text fits in the reserve' do
      remaining(1000)

      helper.pio_eval_len('abc', 40)

      expect(helper.instance_variable_get(:@remaining)).to eq 1000
    end

    it 'cuts text over budget, closes html tags and empties the budget' do
      remaining(200)

      result = helper.pio_eval_len("<p>#{'a' * 500}", 10)

      expect(result).to include('Text is too long').and end_with('</span></p>')
      expect(result.length).to be < 500
      expect(helper.instance_variable_get(:@toolong)).to be true
      expect(helper.instance_variable_get(:@remaining)).to eq 0
    end
  end

  describe '#pio_eval_prot_desc' do
    before { remaining(10_000) }

    it 'uses the small, big and medium reserve depending on the attribute' do
      text = 'x' * 500
      [['published_on', ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_SMALL],
       ['link', ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_BIG],
       ['vendor_link', ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_BIG],
       ['warning', ProtocolsIoHelper::PIO_ELEMENT_RESERVED_LENGTH_MEDIUM]].each do |attribute, reserve|
        remaining(10_000)
        helper.pio_eval_prot_desc(text, attribute)
        expect(helper.instance_variable_get(:@remaining)).to eq(10_000 - (500 - reserve))
      end
    end
  end

  describe '#pio_eval_authors' do
    it 'joins author names' do
      expect(helper.pio_eval_authors([{ 'name' => 'A' }, { 'name' => 'B' }])).to eq 'A, B'
    end

    it 'returns an empty array on malformed input' do
      expect(helper.pio_eval_authors(nil)).to eq []
    end
  end

  describe '#eval_last_modified' do
    it 'formats the newest modification timestamp' do
      steps = [{ 'modified_on' => 1_600_000_000 }, { 'modified_on' => 1_700_000_000 }]

      expect(helper.eval_last_modified(steps)).to eq I18n.l(Time.at(1_700_000_000), format: :full)
    end

    it 'falls back to the epoch when any step lacks a timestamp' do
      # bug: a single step without modified_on makes max() raise, so the valid timestamps are ignored
      steps = [{ 'modified_on' => 1_700_000_000 }, { 'modified_on' => '' }]

      expect(helper.eval_last_modified(steps)).to eq I18n.l(Time.at(0), format: :full)
    end

    it 'falls back to the epoch when there are no timestamps' do
      expect(helper.eval_last_modified([{}])).to eq I18n.l(Time.at(0), format: :full)
    end
  end

  describe '#not_null' do
    it 'turns nil into an empty string' do
      expect(helper.not_null(nil)).to eq ''
      expect(helper.not_null('x')).to eq 'x'
    end
  end

  describe '#close_open_html_tags' do
    it 'closes unterminated tags' do
      expect(helper.close_open_html_tags('<p>abc <b>bold')).to eq '<p>abc <b>bold</b></p>'
    end
  end

  describe '#step_hash_null?' do
    it 'detects empty and filled first components' do
      expect(helper.step_hash_null?([{ 'components' => {} }])).to be true
      expect(helper.step_hash_null?([{ 'components' => { '0' => { 'type_id' => 6 } } }])).to be false
    end

    it 'raises for components given as an array' do
      # bug: dig with a String key on an Array raises TypeError instead of returning true/false
      expect { helper.step_hash_null?([{ 'components' => [] }]) }.to raise_error(TypeError)
    end
  end

  describe '#prepare_for_view' do
    before { remaining(10_000) }

    it 'sanitizes plain text' do
      expect(helper.prepare_for_view(+'<script>alert(1)</script><b>ok</b>', reserved_small)).not_to include('script')
    end

    it 'moves tables out of the text in table mode' do
      result = helper.prepare_for_view(+'x<table><tr><td>1</td></tr></table>', reserved_small, 'table')

      expect(result).to include(I18n.t("#{i18n}.comp_append.table_moved"))
      expect(result).not_to include('<table')
    end

    it 'returns an empty string for nil' do
      expect(helper.prepare_for_view(nil, reserved_small)).to eq ''
    end
  end

  describe '#fill_attributes' do
    before { remaining(10_000) }

    it 'prefixes the value with its translated label' do
      key = 'protocols.protocols_io_import.comp_append.soft_packg.'
      result = helper.fill_attributes('name', 'Tool', key)

      expect(result).to start_with(I18n.t("#{key}name"))
      expect(result).to end_with('Tool')
    end

    it 'uses the shared os label and a separator for os_version' do
      key = 'protocols.protocols_io_import.comp_append.soft_packg.'

      expect(helper.fill_attributes('os_name', 'Linux', key)).to start_with(I18n.t("#{key}os"))
      expect(helper.fill_attributes('os_version', '1.0', key)).to start_with(' , ')
    end

    it 'treats protocol_name as a title' do
      result = helper.fill_attributes('protocol_name', 'a', 'protocols.protocols_io_import.preview.')

      expect(result).to end_with('a ')
    end
  end

  describe 'step component parsers' do
    before { remaining(10_000) }

    it 'wraps descriptions and reports missing ones' do
      expect(helper.pio_stp_1(+'Desc')).to eq '<br>Desc<br>'
      expect(helper.pio_stp_1(+'')).to eq I18n.t("#{i18n}.comp_append.missing_desc")
    end

    it 'parses section titles' do
      expect(helper.pio_stp_6('Title &amp; more')).to eq 'Title & more'
      expect(helper.pio_stp_6(nil)).to eq I18n.t("#{i18n}.comp_append.missing_step")
    end

    it 'parses expected results' do
      expect(helper.pio_stp_17(+'Result')).to eq "#{I18n.t("#{i18n}.comp_append.expected_result")}Result<br>"
      expect(helper.pio_stp_17(nil)).to eq ''
    end

    it 'appends only the present elements' do
      trans = 'protocols.protocols_io_import.comp_append.dataset.'
      result = helper.pio_stp({ 'name' => 'Set' }, %w(name link), trans)

      expect(result).to eq "#{I18n.t("#{trans}name")}Set"
    end
  end

  describe '#protocols_io_fill_desc' do
    before do
      remaining(10_000)
      controller.params[:protocol] = { created_at: '2020-01-01' }
    end

    it 'builds a description from the available attributes' do
      json = {
        'description' => '<p>Main</p>',
        'warning' => 'Careful',
        'published_on' => 1_600_000_000,
        'tags' => [{ 'tag_name' => 'tagA' }, { 'tag_name' => 'tagB' }],
        'created_on' => 'x'
      }

      shortened, unshortened = helper.protocols_io_fill_desc(thaw(json))

      expect(shortened).to include(I18n.t("#{i18n}.preview.description"), 'Main', 'Warning', 'Careful')
      expect(shortened).to include('tagA , tagB')
      expect(shortened).to include('2020-01-01')
      expect(shortened).to include(Time.at(1_600_000_000).utc.to_datetime.to_s)
      expect(unshortened).to include('<p>Main</p>', 'Careful')
    end

    it 'reports a missing description' do
      shortened, unshortened = helper.protocols_io_fill_desc(thaw({}))

      expect(shortened).to include(I18n.t("#{i18n}.comp_append.missing_desc"))
      expect(unshortened).to eq ''
    end
  end

  describe '#protocols_io_guid_reorder_step_json' do
    let(:a) { { 'guid' => 'a', 'previous_guid' => nil } }
    let(:b) { { 'guid' => 'b', 'previous_guid' => 'a' } }
    let(:c) { { 'guid' => 'c', 'previous_guid' => 'b' } }

    it 'orders steps by their previous guid chain' do
      expect(helper.protocols_io_guid_reorder_step_json([c, a, b])).to eq [a, b, c]
    end

    it 'returns blank input as an empty string' do
      expect(helper.protocols_io_guid_reorder_step_json(nil)).to eq ''
    end

    it 'returns the input when there is no first step or only one step' do
      expect(helper.protocols_io_guid_reorder_step_json([b, c])).to eq [b, c]
      expect(helper.protocols_io_guid_reorder_step_json([a])).to eq [a]
    end
  end

  describe '#protocols_io_fill_step' do
    before { controller.params[:protocol] = { created_at: '2020-01-01' } }

    let(:components) do
      [
        { 'type_id' => 6, 'source' => { 'title' => 'Step title' } },
        { 'type_id' => 1, 'source' => { 'description' => '<p>Do it</p><table><tr><td>cell</td></tr></table>' } },
        { 'type_id' => 17, 'source' => { 'body' => 'Expect' } },
        { 'type_id' => 8, 'source' => { 'name' => 'Soft', 'os_name' => 'Linux' } },
        { 'type_id' => 9, 'source' => { 'name' => 'Data' } },
        { 'type_id' => 15, 'source' => { 'name' => "ls\npwd", 'description' => 'List' } },
        { 'type_id' => 18, 'source' => { 'title' => 'Sub' } },
        { 'type_id' => 19, 'source' => { 'body' => 'Safe' } }
      ]
    end
    let(:original) do
      { 'description' => 'Protocol desc', 'steps' => [{ 'guid' => 's1', 'previous_guid' => nil, 'components' => components }] }
    end

    it 'maps a protocols.io protocol into numbered scinote steps' do
      result = helper.protocols_io_fill_step(thaw(original), {})

      expect(result.keys).to eq %w(0 1)
      expect(result['0']).to include('position' => 0, 'name' => 'Protocol info')
      expect(result['0']['description']).to include('Protocol desc')
      expect(result['1']['position']).to eq 1
      expect(result['1']['name']).to eq 'Step title'
      expect(result['1']['description']).to include('Do it', 'Expect', 'Soft', 'Linux', 'Data', 'Sub', 'Safe')
      expect(result['1']['description']).to include('<pre><code>ls<br>pwd</code></pre>')
      expect(result['1']['description']).to include(I18n.t("#{i18n}.comp_append.table_moved"))
      expect(decode_table(result['1']['tables']['0'])).to include('"cell"')
    end

    it 'supports components given as an index keyed hash' do
      original['steps'][0]['components'] = { '0' => components[0], '1' => components[1] }

      result = helper.protocols_io_fill_step(thaw(original), {})

      expect(result['1']['name']).to eq 'Step title'
      expect(result['1']['description']).to include('Do it')
    end
  end

  describe '#get_steps and #get_components' do
    it 'return the collection or an empty array' do
      expect(helper.get_steps({ 'steps' => [1] })).to eq [1]
      expect(helper.get_steps({ 'steps' => 'x' })).to eq []
      expect(helper.get_steps({})).to eq []
      expect(helper.get_components({ 'components' => [2] })).to eq [2]
      expect(helper.get_components({ 'components' => 3 })).to eq []
      expect(helper.get_components({})).to eq []
    end
  end
end
