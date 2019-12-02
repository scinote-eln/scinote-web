/* global GLOBAL_CONSTANTS textValidator */

$.fn.dataTable.render.RowNameValidator = function($input) {
  return textValidator(undefined, $input, 1, GLOBAL_CONSTANTS.NAME_MAX_LENGTH);
};

$.fn.dataTable.render.RepositoryTextValueValidator = function($input) {
  return textValidator(undefined, $input, 1, GLOBAL_CONSTANTS.NAME_MAX_LENGTH);
};

$.fn.dataTable.render.RepositoryListValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryStatusValueValidator = function() {
  return true;
};
