# frozen_string_literal: true

module FileIconsHelper
  def wopi_file?(asset)
    file_ext = asset.file_name.split('.').last&.downcase
    %w(csv ods xls xlsb xlsm xlsx odp pot potm potx pps ppsm
       ppsx ppt pptm pptx doc docm docx dot dotm dotx odt rtf).include?(file_ext)
  end

  def file_fa_icon_class(asset)
    file_ext = asset.file_name.split('.').last&.downcase

    if Extends::FILE_FA_ICON_MAPPINGS[file_ext] # Check for custom mappings or possible overrides
      Extends::FILE_FA_ICON_MAPPINGS[file_ext]
    elsif Constants::FILE_TEXT_FORMATS.include?(file_ext)
      'fa-file-word'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      'fa-file-excel'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      'fa-file-powerpoint'
    elsif %w(pdf).include?(file_ext)
      'fa-file-pdf'
    elsif %w(txt csv tab tex).include?(file_ext)
      'far fa-file-alt'
    elsif Constants::WHITELISTED_IMAGE_TYPES.include?(file_ext)
      'fa-image'
    else
      'fa-paperclip'
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
    end

    # Now check for custom mappings or possible overrides
    image_link = Extends::FILE_ICON_MAPPINGS[file_ext] if Extends::FILE_ICON_MAPPINGS[file_ext]

    if image_link
      if report
        wicked_pdf_image_tag(image_link, class: 'image-icon')
      else
        ActionController::Base.helpers.image_tag(image_link, class: 'image-icon')
      end
    else
      ''
    end
  end

  # For showing in view/edit buttons (WOPI)
  def file_application_icon(asset)
    file_ext = asset.file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      image_link = 'icon_small/docx_file.svg'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      image_link = 'icon_small/xslx_file.svg'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      image_link = 'icon_small/pptx_file.svg'
    end

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
      app = t('result_assets.wopi_word')
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      app = t('result_assets.wopi_excel')
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      app = t('result_assets.wopi_powerpoint')
    end

    if action == 'view'
      t('result_assets.wopi_open_file', app: app)
    elsif action == 'edit'
      t('result_assets.wopi_edit_file', app: app)
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
        class: ['fas', 'asset-icon', file_fa_icon_class(asset)]
      )
    end
    html
  end

  module_function :file_extension_icon_html, :file_extension_icon, :file_fa_icon_class
end
