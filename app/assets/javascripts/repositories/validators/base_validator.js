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

$.fn.dataTable.render.RepositoryNumberValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryDateTimeValueValidator = function($input) {
  let $container = $input.parents().eq(1);
  let $date = $container.find('input[data-datetime-part=date]');
  let $time = $container.find('input[data-datetime-part=time]');

  if (($date.val() === '') === ($time.val() === '')) {
    return true;
  }

  // will be refactored
  $container.addClass('has-error');
  $container.append('<span class="help-block">Set both or none</span>');
  return false;
};

$.fn.dataTable.render.RepositoryDateValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryTimeValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryDateTimeRangeValueValidator = function($input) {
  // will be refactored
  let $container = $input.parents().eq(1);
  let $dateS = $container.find('.start-time input[data-datetime-part=date]');
  let $timeS = $container.find('.start-time input[data-datetime-part=time]');
  let $dateE = $container.find('.end-time input[data-datetime-part=date]');
  let $timeE = $container.find('.end-time input[data-datetime-part=time]');
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
    errorMessage = 'Needs to set all or none';
  } else if (($input.val()) && (startTime > endTime)) {
    isValid = false;
    errorMessage = 'End time is before start time';
  }

  if (isValid) {
    return true;
  }

  $container.addClass('has-error');
  $container.append(`<span class="help-block">${errorMessage}</span>`);
  return false;
};

$.fn.dataTable.render.RepositoryDateRangeValueValidator = function($input) {
  // will be refactored

  let $container = $input.parents().eq(1);
  let $dateS = $container.find('.start-time input[data-datetime-part=date]');
  let $dateE = $container.find('.end-time input[data-datetime-part=date]');
  let isValid = true;
  let errorMessage;
  let endTime;
  let startTime;
  if ($input.val()) {
    startTime = new Date(JSON.parse($input.val()).start_time);
    endTime = new Date(JSON.parse($input.val()).end_time);
  }

  if (!($dateS.val() === '') === ($dateE.val() === '')) {
    isValid = false;
    errorMessage = 'Needs to set all or none';
  } else if (($input.val()) && (startTime > endTime)) {
    isValid = false;
    errorMessage = 'End date is before start date';
  }

  if (isValid) {
    return true;
  }

  $container.addClass('has-error');
  $container.append(`<span class="help-block">${errorMessage}</span>`);
  return false;
};

$.fn.dataTable.render.RepositoryTimeRangeValueValidator = function($input) {
  // will be refactored

  let $container = $input.parents().eq(1);
  let $timeS = $container.find('.start-time input[data-datetime-part=time]');
  let $timeE = $container.find('.end-time input[data-datetime-part=time]');
  let isValid = true;
  let errorMessage;

  if (!($timeS.val() === '') === ($timeE.val() === '')) {
    isValid = false;
    errorMessage = 'Needs to set both or none';
  } else if ($timeS.val() > $timeE.val()) {
    isValid = false;
    errorMessage = 'Needs to set both or none';
    errorMessage = 'End time is before start time';
  }
  if (isValid) {
    return true;
  }
  // will be refactored
  $container.addClass('has-error');
  $container.append(`<span class="help-block">${errorMessage}</span>`);
  return false;
};
