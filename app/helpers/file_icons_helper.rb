module FileIconsHelper
  def wopi_file?(asset)
    file_ext = asset.file_name.split('.').last
    %w(csv ods xls xlsb xlsm xlsx odp pot potm potx pps ppsm
       ppsx ppt pptm pptx doc docm docx dot dotm dotx odt rtf).include?(file_ext)
  end

  def file_fa_icon_class(asset)
    file_ext = asset.file_name.split('.').last

    if Extends::FILE_FA_ICON_MAPPINGS[file_ext] # Check for custom mappings or possible overrides
      return Extends::FILE_FA_ICON_MAPPINGS[file_ext]
    elsif Constants::FILE_TEXT_FORMATS.include?(file_ext)
      return 'fa-file-word'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      return 'fa-file-excel'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      return 'fa-file-powerpoint'
    elsif %w(pdf).include?(file_ext)
      return 'fa-file-pdf'
    elsif %w(txt csv tab tex).include?(file_ext)
      return 'fa-file-alt'
    elsif Constants::WHITELISTED_IMAGE_TYPES.include?(file_ext)
      return 'fa-image'
    else
      return 'fa-paperclip'
    end
  end

  # For showing next to file
  def file_extension_icon(asset)
    file_ext = asset.file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      image_link = 'office/Word-docx_20x20x32.png'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      image_link = 'office/Excel-xlsx_20x20x32.png'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      image_link = 'office/PowerPoint-pptx_20x20x32.png'
    end

    # Now check for custom mappings or possible overrides
    image_link = Extends::FILE_ICON_MAPPINGS[file_ext] if Extends::FILE_ICON_MAPPINGS[file_ext]

    if image_link
      ActionController::Base.helpers.image_tag(image_link, class: 'image-icon')
    else
      ''
    end
  end

  # For showing in view/edit buttons (WOPI)
  def file_application_icon(asset)
    file_ext = asset.file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      image_link = 'office/Word-color_16x16x32.png'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      image_link = 'office/Excel-color_16x16x32.png'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      image_link = 'office/PowerPoint-Color_16x16x32.png'
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
      app = 'Word Online'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      app = 'Excel Online'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      app = 'PowerPoint Online'
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

  def file_extension_icon_html(asset)
    html = file_extension_icon(asset)
    html = "<i class='fas #{file_fa_icon_class(asset)}'></i>" if html.blank?
    html
  end

  module_function :file_extension_icon_html, :file_extension_icon, :file_fa_icon_class
end
