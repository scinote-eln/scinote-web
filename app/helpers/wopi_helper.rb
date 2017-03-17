module WopiHelper
  def wopi_result_view_file_button(result)
    if result.asset.can_perform_action('view')
      link_to view_asset_url(id: result.asset),
              class: 'btn btn-default btn-sm',
              target: '_blank',
              style: 'display: inline-block' do
        "#{file_application_icon(
          result.asset
        )} #{wopi_button_text(result.asset, 'view')}".html_safe
      end
    end
  end

  def wopi_result_edit_file_button(result)
    if can_edit_result_asset_in_module(result.my_module) &&
       result.asset.can_perform_action('edit')
      link_to edit_asset_url(id: result.asset),
              class: 'btn btn-default btn-sm',
              target: '_blank',
              style: 'display: inline-block' do
        "#{file_application_icon(
          result.asset
        )} #{wopi_button_text(result.asset, 'edit')}".html_safe
      end
    end
  end

  def wopi_asset_view_button(asset)
    if asset.can_perform_action('view')
      link_to view_asset_url(id: asset),
              class: 'btn btn-default btn-sm',
              target: '_blank',
              style: 'display: inline-block' do
        "#{file_application_icon(asset)} #{wopi_button_text(asset, 'view')}"
          .html_safe
      end
    end
  end

  def wopi_asset_edit_button(asset)
    if asset.can_perform_action('edit')
      link_to edit_asset_url(id: asset),
              class: 'btn btn-default btn-sm',
              target: '_blank',
              style: 'display: inline-block' do
        "#{file_application_icon(
          asset
        )} #{wopi_button_text(asset, 'edit')}".html_safe
      end
    end
  end

  def wopi_asset_file_name(asset)
    html = '<p style="display: inline-block">'
    html += "#{file_extension_icon(asset)}&nbsp;"
    html += link_to download_asset_path(asset),
                    data: { no_turbolink: true,
                            id: true,
                            status: 'asset-present' } do
                              truncate(
                                asset.file_file_name,
                                length: Constants::FILENAME_TRUNCATION_LENGTH
                              )
                            end
    html += '&nbsp;</p>'
    sanitize_input(html, %w(img a))
  end
end
