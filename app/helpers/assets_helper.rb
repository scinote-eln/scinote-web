module AssetsHelper

  def asset_loading_span(asset)
    res = <<-eos
    <span
      data-status='asset-loading'
      data-filename='#{asset.file_file_name}'
      data-type='#{asset.is_image? ? "image" : "asset"}'
      data-present-url='#{file_present_asset_path(asset, format: :json)}'
      #{asset.is_image? ? "data-preview-url='" + preview_asset_path(asset) + "'" : ""}'
      data-download-url='#{download_asset_path(asset)}'
    >
      <span class='asset-loading-spinner' id='asset-loading-spinner-#{asset.id}'></span>
      #{t("general.file_loading", fileName: asset.file_file_name)}
    </span>
    <script type='text/javascript'>
      $('#asset-loading-spinner-#{asset.id}').spin(
        { lines: 9, length: 4, width: 3, radius: 4, scale: 1, corners: 1,
          color: '#000', opacity: 0.25, rotate: 0, direction: 1, speed: 1,
          trail: 60, fps: 20, zIndex: 100, className: 'spinner', top: '75%',
          left: '50%', shadow: false, hwaccel: false, position: 'relative' }
      );
    </script>
    eos
    res.html_safe
  end
end