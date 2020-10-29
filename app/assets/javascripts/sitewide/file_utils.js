/* eslint no-unused-vars: "off" */
/* global I18n GLOBAL_CONSTANTS HelperModule*/

function validateFileSize(file, showErrorMessage = false) {
  var validSize = true;
  if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
    validSize = false;
  }

  if (!validSize && showErrorMessage) {
    HelperModule.flashAlertMsg(I18n.t('general.file.size_exceeded', { file_size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB }), 'danger');
  }
  return validSize;
}
