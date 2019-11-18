$.fn.dataTable.render.newRowName = function(formId) {
  return `<input form="${formId}"
                 type="text"
                 name="repository_row_name"
                 class="editing"
                 value=""
                 data-type="RowName">`;
};

$.fn.dataTable.render.newRepositoryAssetValue = function(formId, columnId) {
  return '';
};

$.fn.dataTable.render.newRepositoryTextValue = function(formId, columnId) {
  return '';
};

$.fn.dataTable.render.newRepositoryListValue = function(formId, columnId) {
  return '';
};

$.fn.dataTable.render.newRepositoryStatusValue = function(formId, columnId) {
  return '';
};
