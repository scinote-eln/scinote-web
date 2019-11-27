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

$.fn.dataTable.render.defaultRepositoryDateValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryDateTimeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateTimeValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryTimeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryTimeValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryTimeRangeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryTimeRangeValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryDateTimeRangeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateTimeRangeValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryDateRangeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateRangeValue = function(data) {
  return data.value;
};
