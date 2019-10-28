
$.fn.dataTable.render.RepositoryAssetValue = function(data) {
  var asset = data.data;
  return `
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
  `;
};

$.fn.dataTable.render.defaultRepositoryAssetValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryTextValue = function(data) {
  return data.data;
};

$.fn.dataTable.render.defaultRepositoryTextValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryListValue = function(data) {
  return data.data;
};

$.fn.dataTable.render.defaultRepositoryListValue = function() {
  return '';
};
