/* global GLOBAL_CONSTANTS textValidator */

$.fn.dataTable.render.RowNameValidator = function($input) {
  return textValidator(undefined, $input, 1, GLOBAL_CONSTANTS.NAME_MAX_LENGTH);
};
