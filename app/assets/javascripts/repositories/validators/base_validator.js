/* global GLOBAL_CONSTANTS I18n */

$.fn.dataTable.render.RowNameValidator = function($input) {
  var $inputContainer = $input.closest('.sci-input-container');
  var value = $input.val();
  var errorText;

  if (value === '') {
    errorText = I18n.t('repositories.table.name.errors.is_empty');
  } else if (value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
    errorText = I18n.t('repositories.table.name.errors.too_long', { max_length: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB });
  }

  if (errorText) {
    $inputContainer.addClass('error');
    $inputContainer.attr('data-error-text', errorText);
    return false;
  }

  $inputContainer.removeClass('error');
  return true;
};

$.fn.dataTable.render.RepositoryTextValueValidator = function($input) {
  var $inputContainer = $input.closest('.sci-input-container');
  var value = $input.val();
  var errorText;

  if (value.length > GLOBAL_CONSTANTS.TEXT_MAX_LENGTH) {
    errorText = I18n.t('repositories.table.text.errors.too_long', { max_length: GLOBAL_CONSTANTS.TEXT_MAX_LENGTH });
    $inputContainer.addClass('error');
    $inputContainer.attr('data-error-text', errorText);
    return false;
  }

  $inputContainer.removeClass('error');
  return true;
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

$.fn.dataTable.render.RepositoryNumberValueValidator = function($input) {
  if ($input.val().slice(-1) === '.') {
    $input.closest('.text-field').addClass('error').attr(
      'data-error-text',
      I18n.t('repositories.table.number.errors.wrong_format')
    );
    return false;
  }
  $input.removeClass('error');
  return true;
};

$.fn.dataTable.render.RepositoryDateTimeValueValidator = function($input) {
  let $container = $input.parents('.datetime-container');
  let $date = $container.find('input.date-part');
  let $time = $container.find('input.time-part');

  if (($date.val() === '') === ($time.val() === '')) {
    return true;
  }
  $container.find('.date-container')
    .addClass('error')
    .attr('data-error-text', I18n.t('repositories.table.date_time.errors.set_all_or_none'));
  $container.find('.time-container').addClass('error');
  return false;
};

$.fn.dataTable.render.RepositoryDateValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryTimeValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryDateTimeRangeValueValidator = function($input) {
  let $container = $input.parents('.datetime-container');
  let $dateS = $container.find('.start-time input.date-part');
  let $timeS = $container.find('.start-time input.time-part');
  let $dateE = $container.find('.end-time input.date-part');
  let $timeE = $container.find('.end-time input.time-part');
  let isValid = true;
  let errorMessage;
  let startTime;
  let endTime;
  let a = [];

  if ($input.val()) {
    startTime = new Date(JSON.parse($input.val()).start_time);
    endTime = new Date(JSON.parse($input.val()).end_time);
  }

  a.push($dateS.val() === '');
  a.push($timeS.val() === '');
  a.push($dateE.val() === '');
  a.push($timeE.val() === '');

  if (a.filter((v, i, arr) => arr.indexOf(v) === i).length > 1) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.set_all_or_none');
  } else if (($input.val()) && (startTime > endTime)) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.not_valid_range');
  }

  if (isValid) {
    return true;
  }

  $container.find('.date-container').addClass('error');
  $container.find('.time-container').addClass('error');
  $container.find('.date-container').first().attr('data-error-text', errorMessage);
  return false;
};

$.fn.dataTable.render.RepositoryDateRangeValueValidator = function($input) {
  let $container = $input.parents('.datetime-container');
  let $dateS = $container.find('.start-time input.date-part');
  let $dateE = $container.find('.end-time input.date-part');
  let isValid = true;
  let errorMessage;
  let endTime;
  let startTime;
  if ($input.val()) {
    startTime = new Date(JSON.parse($input.val()).start_time);
    endTime = new Date(JSON.parse($input.val()).end_time);
  }

  if (($dateS.val() === '') !== ($dateE.val() === '')) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.set_all_or_none');
  } else if (($input.val()) && (startTime > endTime)) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.not_valid_range');
  }

  if (isValid) {
    return true;
  }

  $container.find('.date-container').addClass('error');
  $container.find('.date-container').first().attr('data-error-text', errorMessage);
  return false;
};

$.fn.dataTable.render.RepositoryTimeRangeValueValidator = function($input) {
  let $container = $input.parents('.datetime-container');
  let $timeS = $container.find('.start-time input.time-part');
  let $timeE = $container.find('.end-time input.time-part');
  let isValid = true;
  let errorMessage;

  if (($timeS.val() === '') !== ($timeE.val() === '')) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.set_all_or_none');
  } else if ($timeS.val() > $timeE.val()) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.not_valid_range');
  }
  if (isValid) {
    return true;
  }

  $container.find('.time-container').addClass('error');
  $container.find('.time-container').first().attr('data-error-text', errorMessage);
  return false;
};
