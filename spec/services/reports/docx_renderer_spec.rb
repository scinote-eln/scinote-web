# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe Reports::DocxRenderer do
  let(:docx_file) { Tempfile.new(['renderer_spec', '.docx']) }
  let(:docx) { Caracal::Document.new(docx_file.path) }
  let(:image_bytes) { File.binread(Rails.root.join('spec/fixtures/files/test.jpg')) }
  let(:blob) { double('blob', download: image_bytes, filename: 'figure.jpg') }

  after do
    docx_file.close
    docx_file.unlink
  end

  def document_node
    docx.save
    xml = Zip::File.open(docx_file.path) { |zip| zip.read('word/document.xml') }
    Nokogiri::XML(xml).remove_namespaces!
  end

  def relationship_targets
    docx.save
    rels = Zip::File.open(docx_file.path) { |zip| zip.read('word/_rels/document.xml.rels') }
    Nokogiri::XML(rels).remove_namespaces!.xpath('//Relationship[@TargetMode="External"]').map { |r| r['Target'] }
  end

  def texts(node = document_node)
    node.xpath('.//t').map(&:text).reject(&:empty?)
  end

  describe '.render_p_element' do
    let(:element) do
      { type: 'p',
        children: [
          { type: 'text', value: 'Bold', style: { bold: true } },
          { type: 'text', value: '' },
          { type: 'br' },
          { type: 'text', value: 'next' },
          { type: 'sup', value: '2' },
          { type: 'sub', value: 'i' },
          { type: 'a', value: 'site', link: '/projects/1' }
        ] }
    end

    it 'draws text with style, line break, super/subscript and links in one paragraph' do
      described_class.render_p_element(docx, element, scinote_url: 'http://sn.test', link_style: { bold: false })
      node = document_node
      expect(node.xpath('//p').size).to eq(1)
      expect(texts).to eq(['Bold', ' ', 'next', ' ', '2', 'i', 'site', ' '])
      expect(node.xpath('//r[t="Bold"]/rPr/b')).not_to be_empty
      expect(node.xpath('//br').size).to eq(1)
      expect(node.xpath('//r[t="2"]/rPr/vertAlign/@val').map(&:value)).to eq(['superscript'])
      expect(node.xpath('//r[t="i"]/rPr/vertAlign/@val').map(&:value)).to eq(['subscript'])
      expect(relationship_targets).to eq(['http://sn.test/projects/1'])
    end

    it 'skips line breaks with skip_br' do
      described_class.render_p_element(docx, element, skip_br: true)
      expect(document_node.xpath('//br')).to be_empty
    end
  end

  describe '.render_link_element' do
    it 'draws a hyperlink for items with a link' do
      docx.p { Reports::DocxRenderer.render_link_element(self, { value: 'ext', link: 'https://example.com/x' }) }
      expect(relationship_targets).to eq(['https://example.com/x'])
      expect(texts).to eq(['ext', ' '])
    end

    it 'draws plain text for items without a link' do
      docx.p { Reports::DocxRenderer.render_link_element(self, { value: 'plain' }, link_style: { bold: true }) }
      expect(relationship_targets).to be_empty
      expect(texts).to eq(['plain', ' '])
    end

    it 'draws no trailing space for an empty value' do
      docx.p { Reports::DocxRenderer.render_link_element(self, { value: '' }) }
      expect(texts).to eq([])
    end
  end

  describe '.render_img_element' do
    let(:element) { { data: 'figure.jpg', blob: blob, style: { width: 200, height: 100, align: :center } } }

    it 'embeds the image with the requested size and alignment' do
      described_class.render_img_element(docx, element)
      node = document_node
      expect(node.xpath('//drawing').size).to eq(1)
      expect(node.xpath('//drawing//extent/@cx').first.value.to_i).to be_positive
      expect(node.xpath('//pPr/jc/@val').map(&:value)).to include('center')
    end

    it 'defaults to left alignment' do
      element[:style].delete(:align)
      described_class.render_img_element(docx, element)
      node = document_node
      expect(node.xpath('//drawing').size).to eq(1)
      expect(node.xpath('//pPr/jc/@val').map(&:value)).to eq(['left'])
    end

    it 'scales the image down to the table column width' do
      element[:style] = { width: 400, height: 200, max_width: 600 }
      described_class.render_img_element(docx, element, table: { columns: 3 })
      expect(element[:style][:width]).to eq(200.0)
      expect(element[:style][:height]).to eq(100.0)
    end

    it 'keeps images that already fit the table column' do
      element[:style] = { width: 100, height: 50, max_width: 600 }
      described_class.render_img_element(docx, element, table: { columns: 3 })
      expect(element[:style]).to include(width: 100, height: 50)
    end
  end

  describe '.render_table_element' do
    let(:table) do
      { type: 'table',
        data: [
          { type: 'tr',
            data: [
              [{ type: 'p', style: { background: 'f0f0f6' }, children: [{ type: 'text', value: 'h1', style: {} }] }],
              [{ type: 'p', style: { vertical_align: :top }, children: [{ type: 'text', value: 'h2', style: {} },
                                                                        { type: 'br' }] }]
            ] },
          { type: 'tr',
            data: [
              [{ type: 'image', data: 'figure.jpg', blob: blob, style: { width: 400, height: 200, max_width: 600 } }],
              [{ type: 'table', data: [{ type: 'tr', data: [[{ type: 'p', children: [{ type: 'text', value: 'nested',
                                                                                         style: {} }] }]] }] }]
            ] }
        ] }
    end

    it 'draws rows, cell contents, nested tables and images' do
      described_class.render_table_element(docx, table)
      node = document_node
      outer = node.xpath('/document/body/tbl')
      expect(outer.size).to eq(1)
      expect(outer.xpath('./tr').size).to eq(2)
      expect(outer.xpath('./tr[1]/tc').map { |tc| texts(tc).join }).to eq(['h1 ', 'h2 '])
      expect(outer.xpath('./tr[2]//tbl//t').map(&:text)).to include('nested')
      expect(outer.xpath('./tr[2]/tc[1]//drawing').size).to eq(1)
      expect(node.xpath('//tc[1]//shd/@fill').map(&:value)).to include('f0f0f6')
      expect(node.xpath('//tc//vAlign/@val').map(&:value)).to include('top', 'center')
    end

    it 'does not emit line breaks inside table cells' do
      described_class.render_table_element(docx, table)
      expect(document_node.xpath('//tc//br')).to be_empty
    end
  end

  describe '.render_list_element' do
    let(:list) do
      { type: 'ul',
        data: [
          ['first', { type: 'ol', data: [%w(nested)] }],
          ['with image', { type: 'image', bookmark_id: 'img_1', data: 'figure.jpg', blob: blob,
                           style: { width: 100, height: 50 } }],
          ['with table', { type: 'table', bookmark_id: 'tbl_1',
                           data: [{ type: 'tr', data: [[{ type: 'p', children: [{ type: 'text', value: 'cell',
                                                                                  style: {} }] }]] }] }],
          [{ type: 'a', value: 'link', link: 'https://example.com' }, { type: 'text', value: 'styled', style: {} }]
        ] }
    end

    it 'draws list items and appends images and tables behind internal bookmarks' do
      described_class.render_list_element(docx, list)
      node = document_node
      items = node.xpath('//p[pPr/numPr]').map { |p| texts(p).join }
      expect(items).to include('first', 'nested', 'link styled')
      expect(items.grep(/with image/).first).to include(
        I18n.t('projects.reports.renderers.lists.appended_image', name: 'figure.jpg')
      )
      expect(items.grep(/with table/).first).to include(I18n.t('projects.reports.renderers.lists.appended_table'))
      expect(node.xpath('//bookmarkStart/@name').map(&:value)).to eq(%w(img_1 tbl_1))
      expect(node.xpath('//bookmarkEnd').size).to eq(2)
      expect(node.xpath('//drawing').size).to eq(1)
      expect(texts(node.xpath('/document/body/tbl').first)).to eq(['cell', ' '])
      expect(texts(node)).to include('figure.jpg')
    end
  end

  describe '.render_asset_image' do
    let(:asset) { double('asset') }
    let(:preview) do
      double('preview', processed: double('processed', url: 'http://localhost:3000/p.jpg?a=1&b=2'), blob: blob)
    end

    before { allow(Reports::Utils).to receive(:image_prepare).with(asset).and_return(preview) }

    it 'returns nil without an asset' do
      expect(described_class.render_asset_image(docx, nil)).to be_nil
      expect(document_node.xpath('//drawing')).to be_empty
    end

    it 'embeds the preview and limits the width to 300 keeping the ratio' do
      allow(FastImage).to receive(:size).and_return([600, 400])
      described_class.render_asset_image(docx, asset)
      extent = document_node.xpath('//drawing//extent').first
      expect(extent['cx'].to_i / extent['cy'].to_i.to_f).to be_within(0.01).of(1.5)
      expect(document_node.xpath('//drawing').size).to eq(1)
    end

    it 'keeps small images at their size' do
      allow(FastImage).to receive(:size).and_return([100, 50])
      described_class.render_asset_image(docx, asset)
      extent = document_node.xpath('//drawing//extent').first
      expect(extent['cx'].to_i / extent['cy'].to_i.to_f).to be_within(0.01).of(2.0)
    end

    it 'draws nothing when the dimensions are unknown' do
      allow(FastImage).to receive(:size).and_return(nil)
      expect(described_class.render_asset_image(docx, asset)).to be_nil
      expect(document_node.xpath('//drawing')).to be_empty
    end

    it 'swallows network errors and logs a warning' do
      allow(FastImage).to receive(:size).and_raise(SocketError, 'getaddrinfo')
      expect(Rails.logger).to receive(:warn).with(/Unable to render docx image due to SocketError/)
      expect(described_class.render_asset_image(docx, asset)).to be_nil
    end

    it 'downloads the image of an ActiveStorage preview' do
      active_preview = ActiveStorage::Preview.allocate
      allow(active_preview).to receive_messages(
        processed: double('processed', url: 'http://localhost:3000/p.jpg?x=1'),
        image: double('image', download: image_bytes)
      )
      allow(Reports::Utils).to receive(:image_prepare).with(asset).and_return(active_preview)
      allow(FastImage).to receive(:size).and_return([100, 100])
      described_class.render_asset_image(docx, asset)
      expect(document_node.xpath('//drawing').size).to eq(1)
    end
  end
end
