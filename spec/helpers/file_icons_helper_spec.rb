# frozen_string_literal: true

require 'rails_helper'

describe FileIconsHelper, type: :helper do
  # Plain doubles keep these examples free of database and storage access.
  def asset_double(file_name, attached: false, asset_type: nil)
    file = double('ActiveStorage::Attached', attached?: attached,
                                             metadata: { 'asset_type' => asset_type })
    double('Asset', file_name: file_name, file: file)
  end

  describe '#wopi_file?' do
    it 'accepts office document extensions regardless of case' do
      expect(helper.wopi_file?(asset_double('Report.DOCX'))).to be true
      expect(helper.wopi_file?(asset_double('sheet.xlsm'))).to be true
      expect(helper.wopi_file?(asset_double('deck.pptx'))).to be true
      expect(helper.wopi_file?(asset_double('notes.odt'))).to be true
    end

    it 'rejects non office extensions' do
      expect(helper.wopi_file?(asset_double('image.png'))).to be false
      expect(helper.wopi_file?(asset_double('no_extension'))).to be false
    end

    it 'accepts the wopi test extensions only when WOPI_TEST_ENABLED is true' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WOPI_TEST_ENABLED').and_return('true')
      expect(helper.wopi_file?(asset_double('file.wopitest'))).to be true
      expect(helper.wopi_file?(asset_double('file.wopitestx'))).to be true
    end

    it 'rejects the wopi test extensions when WOPI_TEST_ENABLED is not true' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WOPI_TEST_ENABLED').and_return('false')
      expect(helper.wopi_file?(asset_double('file.wopitest'))).to be false
    end
  end

  describe '#file_fa_icon_class' do
    it 'uses the custom mapping from Extends when present' do
      stub_const('Extends::FILE_FA_ICON_MAPPINGS', { 'zzz' => 'custom-zzz-icon' })
      expect(helper.send(:file_fa_icon_class, asset_double('thing.ZZZ'))).to eq 'custom-zzz-icon'
    end

    it 'maps text, table, presentation and pdf files to their icons' do
      expect(helper.send(:file_fa_icon_class, asset_double('a.docx'))).to eq 'sn-icon-file-word'
      expect(helper.send(:file_fa_icon_class, asset_double('a.xlsx'))).to eq 'sn-icon-file-excel'
      expect(helper.send(:file_fa_icon_class, asset_double('a.pptx'))).to eq 'sn-icon-file-powerpoint'
      expect(helper.send(:file_fa_icon_class, asset_double('a.pdf'))).to eq 'sn-icon-file-pdf'
    end

    it 'maps plain text, image and marvinjs / gene sequence assets' do
      expect(helper.send(:file_fa_icon_class, asset_double('notes.txt'))).to eq 'sn-icon-result-text'
      expect(helper.send(:file_fa_icon_class, asset_double('data.csv'))).to eq 'sn-icon-file-excel'
      expect(helper.send(:file_fa_icon_class, asset_double('photo.png'))).to eq 'sn-icon-result-image'
      expect(
        helper.send(:file_fa_icon_class, asset_double('mol.cdx', attached: true, asset_type: 'marvinjs'))
      ).to eq 'sn-icon-marvinjs'
      expect(
        helper.send(:file_fa_icon_class, asset_double('seq.gb', attached: true, asset_type: 'gene_sequence'))
      ).to eq 'sn-icon-sequence-editor'
    end

    it 'falls back to the generic attachment icon' do
      expect(helper.send(:file_fa_icon_class, asset_double('archive.zip'))).to eq 'sn-icon-attachment'
      expect(
        helper.send(:file_fa_icon_class, asset_double('blob.bin', attached: true, asset_type: 'other'))
      ).to eq 'sn-icon-attachment'
    end
  end

  describe '#file_extension_icon' do
    it 'renders an image tag for office documents' do
      html = helper.send(:file_extension_icon, asset_double('a.docx'))
      expect(html).to include('word-document', 'image-icon')
    end

    it 'renders excel and powerpoint icons' do
      expect(helper.send(:file_extension_icon, asset_double('a.xls'))).to include('excel-document')
      expect(helper.send(:file_extension_icon, asset_double('a.ppt'))).to include('powerpoint-document')
    end

    it 'renders the marvinjs and gene sequence icons for attached assets' do
      marvin = asset_double('mol.cdx', attached: true, asset_type: 'marvinjs')
      sequence = asset_double('seq.gb', attached: true, asset_type: 'gene_sequence')
      expect(helper.send(:file_extension_icon, marvin)).to include('marvinjs_file')
      expect(helper.send(:file_extension_icon, sequence)).to include('sequence-editor')
    end

    it 'returns an empty string when there is no icon' do
      expect(helper.send(:file_extension_icon, asset_double('archive.zip'))).to eq ''
    end

    it 'uses the custom icon mapping from Extends over the built in one' do
      stub_const('Extends::FILE_ICON_MAPPINGS', { 'docx' => 'icon_small/excel-document.svg' })
      expect(helper.send(:file_extension_icon, asset_double('a.docx'))).to include('excel-document')
    end

    it 'inlines the icon as base64 when rendering a report' do
      allow(helper).to receive(:wicked_pdf_asset_base64)
        .with('icon_small/word-document.svg').and_return('data:image/svg+xml;base64,AAA')
      html = helper.send(:file_extension_icon, asset_double('a.docx'), true)
      expect(html).to include('data:image/svg+xml;base64,AAA')
    end
  end

  describe '#file_extension_icon_html' do
    it 'returns the image icon when one exists' do
      expect(helper.send(:file_extension_icon_html, asset_double('a.docx'))).to include('word-document')
    end

    it 'falls back to an icon font element when there is no image icon' do
      html = helper.send(:file_extension_icon_html, asset_double('a.pdf'))
      expect(html).to eq '<i class="sn-icon asset-icon sn-icon-file-pdf"></i>'
    end
  end

  describe '#file_application_url' do
    it 'returns the icon path for text, table and presentation formats' do
      expect(helper.file_application_url(asset_double('a.doc'))).to eq 'icon_small/word-document.svg'
      expect(helper.file_application_url(asset_double('a.xlsb'))).to eq 'icon_small/excel-document.svg'
      expect(helper.file_application_url(asset_double('a.ppsx'))).to eq 'icon_small/powerpoint-document.svg'
    end

    it 'returns nil for other formats' do
      expect(helper.file_application_url(asset_double('a.png'))).to be_nil
    end
  end

  describe '#sn_icon_for' do
    it 'returns the sn icon name for each office family' do
      expect(helper.sn_icon_for(asset_double('a.rtf'))).to eq 'file-word'
      expect(helper.sn_icon_for(asset_double('a.ods'))).to eq 'file-excel'
      expect(helper.sn_icon_for(asset_double('a.odp'))).to eq 'file-powerpoint'
    end

    it 'returns nil for other formats' do
      expect(helper.sn_icon_for(asset_double('a.txt'))).to be_nil
    end
  end

  describe '#file_application_icon' do
    it 'renders the image tag for office files' do
      expect(helper.file_application_icon(asset_double('a.docx'))).to include('word-document')
    end

    it 'returns an empty string for other files' do
      expect(helper.file_application_icon(asset_double('a.png'))).to eq ''
    end
  end

  describe '#wopi_button_text' do
    it 'returns the view text for each application' do
      expect(helper.wopi_button_text(asset_double('a.docx'), 'view'))
        .to eq I18n.t('result_assets.wopi_open_file', app: I18n.t('result_assets.wopi_word'))
      expect(helper.wopi_button_text(asset_double('a.xlsx'), 'view'))
        .to eq I18n.t('result_assets.wopi_open_file', app: I18n.t('result_assets.wopi_excel'))
      expect(helper.wopi_button_text(asset_double('a.pptx'), 'view'))
        .to eq I18n.t('result_assets.wopi_open_file', app: I18n.t('result_assets.wopi_powerpoint'))
    end

    it 'returns the edit text when the action is edit' do
      expect(helper.wopi_button_text(asset_double('a.docx'), 'edit'))
        .to eq I18n.t('result_assets.wopi_edit_file', app: I18n.t('result_assets.wopi_word'))
    end

    it 'returns nil for an unknown action' do
      expect(helper.wopi_button_text(asset_double('a.docx'), 'print')).to be_nil
    end
  end

  describe '#wopi_content_type' do
    it 'returns the OOXML content type for docx, xlsx and pptx' do
      expect(helper.wopi_content_type('docx'))
        .to eq 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      expect(helper.wopi_content_type('xlsx'))
        .to eq 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      expect(helper.wopi_content_type('pptx'))
        .to eq 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    end

    it 'returns nil for unsupported extensions' do
      expect(helper.wopi_content_type('odt')).to be_nil
    end
  end
end
