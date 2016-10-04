module FileIconsHelper
  def wopi_file?(asset)
    file_ext = asset.file_file_name.split('.').last
    %w(doc docx xls xlsx ppt pptx).include?(file_ext)
  end

  # For showing next to file
  def file_extension_icon(asset)
    file_ext = asset.file_file_name.split('.').last
    if %w(doc docx).include?(file_ext)
      image_link = 'office/Word-docx_20x20x32.png'
    elsif %w(xls xlsx).include?(file_ext)
      image_link = 'office/Excel-xlsx_20x20x32.png'
    elsif %w(ppt pptx).include?(file_ext)
      image_link = 'office/PowerPoint-pptx_20x20x32.png'
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
    if %w(doc docx).include?(file_ext)
      image_link = 'office/Word-color_16x16x32.png'
    elsif %w(xls xlsx).include?(file_ext)
      image_link = 'office/Excel-color_16x16x32.png'
    elsif %w(ppt pptx).include?(file_ext)
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
    if %w(doc docx).include?(file_ext)
      app = 'Word Online'
    elsif %w(xls xlsx).include?(file_ext)
      app = 'Excel Online'
    elsif %w(ppt pptx).include?(file_ext)
      app = 'PowerPoint Online'
    end

    if action == 'view'
      t('result_assets.wopi_open_file', app: app)
    elsif action == 'edit'
      t('result_assets.wopi_edit_file', app: app)
    end
  end
end
