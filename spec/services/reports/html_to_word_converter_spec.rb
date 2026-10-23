# frozen_string_literal: true

require 'rails_helper'

describe Reports::HtmlToWordConverter do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:docx) { double('docx') }
  let(:report) { described_class.new(docx) }

  describe 'html_list' do
    let(:text) do
      '<body><ul><li>1</li><li>2<ul><li>one</li><li>two<ol><li>uno</li><li>due</li>'\
      '</ol></li></ul></li><li>3</li><li>4</li><li>5</li></ul></body>'
    end
    let(:xml_elements) { Nokogiri::HTML(text).css('body').children.first }
    let(:result) do
      {
        type: 'ul',
        data: [%w(1),
               ['2', { type: 'ul', data: [%w(one), ['two', { type: 'ol', data: [%w(uno), %w(due)] }]] }],
               %w(3), %w(4), %w(5)]
      }
    end
    it '' do
      expect(report.__send__(:list_element, xml_elements)).to be == result
    end
  end

  describe '.tiny_mce_table_element' do
    let(:text) do
      # rubocop:disable Layout/LineLength
      '<body><table style="border-collapse: collapse; width: 100%; height: 28px;" border="1" data-mce-style="border-collapse: collapse; width: 100%; height: 28px;"><tbody><tr style="height: 10px;"><td style="width: 50%; height: 10px;">1</td><td style="width: 50%; height: 10px;">2</td></tr><tr style="height: 18px;"><td style="width: 50%; height: 18px;">3</td><td style="width: 50%; height: 18px;">4</td></tr></tbody></table></body>'
      # rubocop:enable Layout/LineLength
    end
    let(:xml_elements) { Nokogiri::HTML(text).css('body').children.first }
    let(:result) do
      {
        data: [
          {
            data: [
              [{ children: [{ style: {}, type: 'text', value: '1' }], type: 'p' }],
              [{ children: [{ style: {}, type: 'text', value: '2' }], type: 'p' }]
            ],
            type: 'tr'
          },
          {
            data: [
              [{ children: [{ style: {}, type: 'text', value: '3' }], type: 'p' }],
              [{ children: [{ style: {}, type: 'text', value: '4' }], type: 'p' }]
            ],
            type: 'tr'
          }
        ],
        type: 'table'
      }
    end

    it '' do
      expect(report.__send__(:tiny_mce_table_element, xml_elements)).to be == result
    end
  end

  describe '#html_to_word_converter' do
    # Records what the converter draws instead of building a real docx document.
    let(:style_recorder_class) do
      Class.new do
        attr_reader :styles

        def initialize
          @styles = {}
        end

        def method_missing(name, *args)
          @styles[name] = args.first
        end

        def respond_to_missing?(*)
          true
        end
      end
    end
    let(:recording_docx) do
      recorder_class = style_recorder_class
      Class.new do
        attr_reader :calls

        define_method(:initialize) { @calls = [] }

        define_method(:p) do |value, &block|
          recorder = recorder_class.new
          recorder.instance_eval(&block) if block
          @calls << [:p, value, recorder.styles]
        end

        %i(h1 h2 h3 h4 h5 h6).each do |heading|
          define_method(heading) { |value| @calls << [heading, value] }
        end
      end.new
    end
    let(:converter) { described_class.new(recording_docx, scinote_url: 'https://sn.example', link_style: { color: '0000FF' }) }
    let(:rendered) { [] }

    before do
      %i(render_p_element render_table_element render_img_element render_list_element).each do |meth|
        allow(Reports::DocxRenderer).to receive(meth) { |_docx, element, *rest| rendered << [meth, element, rest] }
      end
    end

    def convert(html)
      converter.html_to_word_converter("<html><body>#{html}</body></html>")
      rendered
    end

    def paragraph_children(html)
      result = convert(html)
      expect(result.map(&:first)).to eq [:render_p_element]
      result.first[1][:children]
    end

    describe 'plain text and inline elements' do
      it 'draws text as a single paragraph passing the url and link style options' do
        result = convert('<p>Hello</p><p>world</p>')
        expect(result.size).to eq 1
        meth, element, rest = result.first
        expect(meth).to eq :render_p_element
        expect(element).to eq(type: 'p', children: [{ type: 'text', value: 'Hello', style: {} },
                                                    { type: 'text', value: 'world', style: {} }])
        expect(rest).to eq [{ scinote_url: 'https://sn.example', link_style: { color: '0000FF' } }]
      end

      it 'always draws a trailing paragraph, empty for empty html' do
        expect(convert('').map { |r| r[1] }).to eq [{ type: 'p', children: [] }]
      end

      it 'skips non breaking space only nodes and strips them from text' do
        expect(paragraph_children("<p>\u00a0</p><p>a\u00a0b</p>").map { |c| c[:value] }).to eq ['ab']
      end

      it 'keeps line breaks' do
        expect(paragraph_children('a<br>b').map { |c| c[:type] }).to eq %w(text br text)
      end

      it 'keeps sup and sub elements' do
        expect(paragraph_children('x<sup>2</sup><sub>i</sub>')).to eq [
          { type: 'text', value: 'x', style: {} },
          { type: 'sup', value: '2' },
          { type: 'sub', value: 'i' }
        ]
      end

      it 'marks strong and em text bold and italic' do
        children = paragraph_children('<strong>b</strong><em>i</em>')
        expect(children.map { |c| c[:style] }).to eq [{ bold: true }, { italic: true }]
      end

      it 'marks underlined text' do
        children = paragraph_children('<span style="text-decoration: underline">u</span>')
        expect(children.first[:style]).to eq(underline: true)
      end

      it 'wraps smart annotation text in brackets' do
        children = paragraph_children('<span class="sa-type">TSK1</span>')
        expect(children.first[:value]).to eq '[TSK1]'
      end
    end

    describe 'colors' do
      it 'keeps dark hex colors without the hash' do
        children = paragraph_children('<span style="color: #112233">c</span>')
        expect(children.first[:style]).to eq(color: '112233')
      end

      it 'converts rgb colors to hex' do
        children = paragraph_children('<span style="color: rgb(255, 0, 16)">c</span>')
        expect(children.first[:style]).to eq(color: 'FF0010')
      end

      it 'drops colors that are too light to read' do
        children = paragraph_children('<span style="color: #fafafa">c</span>')
        expect(children.first[:style]).to eq({})
      end
    end

    describe 'newline elements (aligned text and headings)' do
      it 'draws headings through the heading method of the document' do
        convert('<h2>Title</h2>')
        expect(recording_docx.calls).to eq [[:h2, 'Title']]
      end

      it 'draws center aligned text as its own paragraph with its style' do
        convert('<p style="text-align: center; color: #112233">Mid</p>')
        expect(recording_docx.calls).to eq [[:p, 'Mid', { align: :center, color: '112233', bold: nil, italic: nil }]]
      end

      it 'keeps justified text inline' do
        convert('<p style="text-align: justify">Just</p>')
        expect(recording_docx.calls).to be_empty
        expect(rendered.first[1][:children].first).to include(type: 'text', value: 'Just')
      end

      it 'flushes pending inline text before a newline element' do
        convert('before<h1>Head</h1>after')
        expect(rendered.map { |r| r[1][:children].map { |c| c[:value] } }).to eq [%w(before), %w(after)]
        expect(recording_docx.calls).to eq [[:h1, 'Head']]
      end
    end

    describe 'links' do
      it 'keeps href and text' do
        children = paragraph_children('<a href="https://x.test/a">site</a>')
        expect(children).to eq [{ type: 'a', value: 'site', link: 'https://x.test/a' }]
      end

      it 'has no link when there is no href' do
        expect(paragraph_children('<a>anchor</a>')).to eq [{ type: 'a', value: 'anchor', link: nil }]
      end

      it 'turns record info links into plain hashtag text' do
        children = paragraph_children('<a class="record-info-link" href="/x">item</a>')
        expect(children).to eq [{ type: 'a', value: '#item', link: nil }]
      end

      it 'prefixes smart annotation tags with a hashtag' do
        children = paragraph_children('<span class="atwho-inserted"><a href="/t">task</a></span>')
        expect(children).to eq [{ type: 'a', value: '#task', link: '/t' }]
      end

      it 'prefixes user mentions with an at sign' do
        children = paragraph_children('<a class="atwho-user-popover" href="/u">jane</a>')
        expect(children.first).to include(value: '@jane')
      end
    end

    describe 'lists' do
      it 'renders lists as standalone elements' do
        result = convert('<ul><li>a</li><li>b</li></ul>')
        expect(result.first[0]).to eq :render_list_element
        expect(result.first[1]).to eq(type: 'ul', data: [%w(a), %w(b)])
      end

      it 'extracts links, formatted text and nested content of items' do
        result = convert('<ol><li><a href="/l">lnk</a></li><li><strong>bold</strong></li><li><ul><li>n</li></ul></li></ol>')
        expect(result.first[1]).to eq(type: 'ol', data: [
                                        [{ type: 'a', value: 'lnk', link: '/l' }],
                                        ['bold'],
                                        [{ type: 'ul', data: [%w(n)] }]
                                      ])
      end

      it 'ignores items that are not list items' do
        result = convert('<ul><li>a</li><div>x</div></ul>')
        expect(result.first[1][:data]).to eq [%w(a)]
      end
    end

    describe 'tables' do
      let(:table) do
        '<table><tbody><tr><td style="background-color: #ff0000; vertical-align: top">A</td>' \
          '<td background="#00ff00">B<br>C</td></tr></tbody></table>'
      end

      it 'renders tables with cell content and cell styling' do
        meth, element = convert(table).first
        expect(meth).to eq :render_table_element
        row = element[:data].first
        expect(row[:type]).to eq 'tr'
        first_cell, second_cell = row[:data]
        expect(first_cell).to eq [{ type: 'p', children: [{ type: 'text', value: 'A', style: {} }],
                                    style: { background: 'ff0000', vertical_align: :top } }]
        expect(second_cell.first[:children].map { |c| c[:type] }).to eq %w(text br text)
        expect(second_cell.first).not_to have_key(:style)
      end

      it 'parses background shorthand and rgb values of cells' do
        html = '<table><tbody><tr><td style="background: rgb(0, 128, 255)">A</td></tr></tbody></table>'
        cell = convert(html).first[1][:data].first[:data].first
        expect(cell.first[:style]).to eq(background: '0080FF')
      end

      it 'does not turn aligned text inside cells into newline elements' do
        html = '<table><tbody><tr><td><p style="text-align: center">A</p></td></tr></tbody></table>'
        cell = convert(html).first[1][:data].first[:data].first
        expect(cell.first).to include(type: 'p')
        expect(cell.first[:children].first[:type]).to eq 'text'
      end
    end

    describe 'images' do
      let(:asset) { create :tiny_mce_asset }
      let(:token) { Base62.encode(asset.id) }
      let(:image_html) { "<img data-mce-token=\"#{token}\" width=\"#{width}\" height=\"#{height}\" style=\"#{style}\">" }
      let(:width) { 100 }
      let(:height) { 50 }
      let(:style) { '' }
      let(:processed) { double('processed', url: 'http://files.test/img.png?a=1&b=2') }
      let(:representation) { double('representation', processed: processed) }

      before do
        allow(Reports::Utils).to receive(:image_prepare).and_return(representation)
        allow(FastImage).to receive(:size).and_return([400, 200])
      end

      it 'renders an image element with the url, blob and style' do
        meth, element = convert(image_html).first
        expect(meth).to eq :render_img_element
        expect(Reports::Utils).to have_received(:image_prepare).with(asset)
        expect(element).to include(type: 'image', data: 'http://files.test/img.png?a=1', blob: asset.blob)
        expect(element[:style]).to include(width: 100, height: 50)
      end

      it 'uses the real image size when width and height attributes are missing' do
        html = "<img data-mce-token=\"#{token}\">"
        expect(convert(html).first[1][:style]).to include(width: 400, height: 200)
      end

      it 'scales images wider than the page keeping the ratio' do
        max_width = (Constants::REPORT_DOCX_WIDTH - Constants::REPORT_DOCX_MARGIN_LEFT - Constants::REPORT_DOCX_MARGIN_RIGHT) / 20
        html = "<img data-mce-token=\"#{token}\" width=\"#{max_width * 2}\" height=\"100\">"
        style = convert(html).first[1][:style]
        expect(style).to include(width: max_width, height: 50, max_width: max_width)
      end

      context 'with alignment styles' do
        it 'centers images with a right margin' do
          html = "<img data-mce-token=\"#{token}\" style=\"margin-right: auto; margin-left: auto\">"
          expect(convert(html).first[1][:style][:align]).to eq :center
        end

        it 'aligns floated images to the right' do
          html = "<img data-mce-token=\"#{token}\" style=\"float: right\">"
          expect(convert(html).first[1][:style][:align]).to eq :right
        end

        it 'aligns other styled images to the left' do
          html = "<img data-mce-token=\"#{token}\" style=\"border: 0\">"
          expect(convert(html).first[1][:style][:align]).to eq :left
        end
      end

      it 'skips images without a token' do
        expect(convert('<img src="x.png">').map(&:first)).to eq [:render_p_element]
        expect(rendered.first[1][:children]).to eq []
      end

      it 'skips images whose asset does not exist' do
        html = "<img data-mce-token=\"#{Base62.encode(asset.id + 1000)}\">"
        expect(convert(html).map(&:first)).to eq [:render_p_element]
      end

      it 'skips images whose size cannot be determined' do
        allow(FastImage).to receive(:size).and_return(nil)
        expect(convert(image_html).map(&:first)).to eq [:render_p_element]
      end

      it 'replaces images that fail to process with an error note' do
        allow(Reports::Utils).to receive(:image_prepare).and_raise(StandardError, 'boom')
        allow(Rails.logger).to receive(:error)
        children = paragraph_children(image_html)
        expect(children).to eq [{ type: 'text', style: { italic: true },
                                  value: I18n.t('projects.reports.index.generation.file_preview_generation_error') }]
      end

      it 'puts images found in lists next to the text with a bookmark id' do
        item = convert("<ul><li>#{image_html}</li></ul>").first[1][:data].first.first
        expect(item).to include(type: 'image', bookmark_id: a_string_matching(/\A\h{32}\z/))
      end
    end
  end

  describe 'list_element with tables' do
    it 'embeds tables found in list items with a bookmark id' do
      html = '<body><ul><li><table><tbody><tr><td>x</td></tr></tbody></table></li></ul></body>'
      list = report.__send__(:list_element, Nokogiri::HTML(html).css('body').children.first)
      table = list[:data].first.first
      expect(table).to include(type: 'table', bookmark_id: a_string_matching(/\A\h{32}\z/))
    end
  end
end
