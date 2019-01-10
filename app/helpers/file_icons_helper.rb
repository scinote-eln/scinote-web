module FileIconsHelper
  def wopi_file?(asset)
    file_ext = asset.file_file_name.split('.').last
    %w(csv ods xls xlsb xlsm xlsx odp pot potm potx pps ppsm ppsx ppt pptm pptx doc docm docx dot dotm dotx odt rtf).include?(file_ext)
  end

  # For showing next to file
  def file_fa_icon_class(asset)
    file_ext = asset.file_file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      fa_class = 'fa-file-word'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      fa_class = 'fa-file-excel'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      fa_class = 'fa-file-powerpoint'
    elsif %w(pdf).include?(file_ext)
      fa_class = 'fa-file-pdf'
    elsif %w(txt csv tab tex).include?(file_ext)
      fa_class = 'fa-file-alt'
    end

    # Now check for custom mappings or possible overrides
    if Extends::FILE_ICON_MAPPINGS[file_ext]
      fa_class = Extends::FILE_FA_ICON_MAPPINGS[file_ext]
    end

    fa_class = 'fa-file' if fa_class.blank?
    fa_class
  end

  # For showing next to file
  def file_extension_icon(asset)
    file_ext = asset.file_file_name.split('.').last
    if Constants::FILE_TEXT_FORMATS.include?(file_ext)
      image_link = 'office/Word-docx_20x20x32.png'
    elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
      image_link = 'office/Excel-xlsx_20x20x32.png'
    elsif Constants::FILE_PRESENTATION_FORMATS.include?(file_ext)
      image_link = 'office/PowerPoint-pptx_20x20x32.png'
    end

    # Now check for custom mappings or possible overrides
    if Extends::FILE_ICON_MAPPINGS[file_ext]
      image_link = Extends::FILE_ICON_MAPPINGS[file_ext]
    end

    if image_link
      image_tag image_link
    else
      ''
    end
  end

  # For showing in view/edit buttons (WOPI)
  def file_application_icon(asset)
    file_ext = asset.file_file_name.split('.').last
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
    file_ext = asset.file_file_name.split('.').last
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
end
