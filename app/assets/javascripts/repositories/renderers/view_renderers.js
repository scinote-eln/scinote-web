$.fn.dataTable.render.RepositoryAssetValue = function(data) {
  var asset = data.value;
  return `
    <div class="asset-value-cell">
      ${asset.icon_html}
      <a  class="file-preview-link" 
        id="modal_link${asset.id}" 
        data-no-turbolink="true" 
        data-id="true" 
        data-status="asset-present" 
        data-preview-url="${asset.preview_url}" 
        href="${asset.url}"
        >
      ${asset.file_name}
    </a>
    </div>
  `;
};

$.fn.dataTable.render.defaultRepositoryAssetValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryTextValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryTextValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryListValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryListValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryStatusValue = function(data) {
  return '<i class="repository-status-value-icon">' + data.value.icon + '</i>' + data.value.status;
};

$.fn.dataTable.render.defaultRepositoryStatusValue = function() {
  return '';
};
