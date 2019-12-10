/* global GLOBAL_CONSTANTS textValidator I18n */

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

$.fn.dataTable.render.RepositoryAssetValueValidator = function($input) {
  let file = $input[0].files[0];
  if (!file) return true;

  let valid = (file.size < GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024);
  if (valid) return true;

  let errorMessage = I18n.t('general.file.size_exceeded', { file_size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB });
  let $btn = $input.next('.file-upload-button');
  $btn.addClass('error');
  $btn.attr('data-error-text', errorMessage);
  return false;
};

$.fn.dataTable.render.RepositoryChecklistValueValidator = function() {
  return true;
};