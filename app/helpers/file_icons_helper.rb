# frozen_string_literal: true

module FileIconsHelper
  def wopi_file?(asset)
    file_ext = asset.file_name.split('.').last&.downcase
    %w(ods xls xlsb xlsm xlsx odp pot potm potx pps ppsm
       ppsx ppt pptm pptx doc docm docx dot dotm dotx odt rtf).include?(file_ext)
  end

  def file_fa_icon_class(asset)
    file_ext = asset.file_name.split('.').last&.downcase

    if Extends::FILE_FA_ICON_MAPPINGS[file_ext] # Check for custom mappings or possible overrides
      Extends::FILE_FA_ICON_MAPPINGS[file_ext]
    elsif Constants::FILE_TEXT_FORMATS.include?(file_ext)
      'sn-icon-file-word'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      'sn-icon-file-excel'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      'sn-icon-file-powerpoint'
    elsif %w(pdf).include?(file_ext)
      'sn-icon-file-pdf'
    elsif %w(txt csv tab tex).include?(file_ext)
      'sn-icon-result-text'
    elsif Constants::WHITELISTED_IMAGE_TYPES.include?(file_ext)
      'sn-icon-result-image'
    elsif asset.file.attached? && asset.file.metadata['asset_type'] == 'marvinjs'
      'sn-icon-marvinjs'
    elsif asset.file.attached? && asset.file.metadata['asset_type'] == 'gene_sequence'
      'sn-icon-sequence-editor'
    else
      'sn-icon-attachment'
    end
  end

  # For showing next to file
  def file_extension_icon(asset, report = false)
    file_ext = asset.file_name.split('.').last&.downcase
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      image_link = 'icon_small/docx_file.svg'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      image_link = 'icon_small/xslx_file.svg'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      image_link = 'icon_small/pptx_file.svg'
    elsif asset.file.attached? && asset.file.metadata['asset_type'] == 'marvinjs'
      image_link = 'icon_small/marvinjs_file.svg'
    elsif asset.file.attached? && asset.file.metadata['asset_type'] == 'gene_sequence'
      image_link = 'icon_small/sequence-editor.svg'
    end

    # Now check for custom mappings or possible overrides
    image_link = Extends::FILE_ICON_MAPPINGS[file_ext] if Extends::FILE_ICON_MAPPINGS[file_ext]

    if image_link
      image_link = wicked_pdf_asset_base64(image_link) if report

      ActionController::Base.helpers.image_tag(image_link, class: 'image-icon')
    else
      ''
    end
  end

  # For showing in view/edit icon url (WOPI)
  def file_application_url(asset)
    file_ext = asset.file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      'icon_small/docx_file.svg'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      'icon_small/xslx_file.svg'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      'icon_small/pptx_file.svg'
    end
  end

  def sn_icon_for(asset)
    file_ext = asset.file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      'file-word'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      'file-excel'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      'file-powerpoint'
    end
  end

  # For showing in view/edit buttons (WOPI)
  def file_application_icon(asset)
    image_link = file_application_url(asset)
    if image_link
      image_tag image_link
    else
      ''
    end
  end

  # Shows correct WOPI application text (Word Online/Excel ..)
  def wopi_button_text(asset, action)
    file_ext = asset.file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      app = I18n.t('result_assets.wopi_word')
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      app = I18n.t('result_assets.wopi_excel')
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      app = I18n.t('result_assets.wopi_powerpoint')
    end

    if action == 'view'
      I18n.t('result_assets.wopi_open_file', app: app)
    elsif action == 'edit'
      I18n.t('result_assets.wopi_edit_file', app: app)
    end
  end

  # Returns correct content type for given extension
  def wopi_content_type(extension)
    case extension
    when 'docx'
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when 'xlsx'
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when 'pptx'
      'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    end
  end

  def file_extension_icon_html(asset, report = false)
    html = file_extension_icon(asset, report)
    if html.blank?
      html = ActionController::Base.helpers.content_tag(
        :i,
        '',
        class: ['sn-icon', 'asset-icon', file_fa_icon_class(asset)]
      )
    end
    html
  end

  module_function :file_extension_icon_html, :file_extension_icon, :file_fa_icon_class
end
