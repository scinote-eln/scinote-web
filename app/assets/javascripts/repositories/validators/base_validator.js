/* global GLOBAL_CONSTANTS I18n */

$.fn.dataTable.render.RowNameValidator = function($input) {
  var $inputContainer = $input.closest('.sci-input-container');
  var value = $input.val();
  var errorText;

  if (value === '') {
    errorText = I18n.t('repositories.table.name.errors.is_empty');
  } else if (value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
    errorText = I18n.t('repositories.table.name.errors.too_long', { max_length: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
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
  return true;
};

$.fn.dataTable.render.RepositoryDateValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryTimeValueValidator = function() {
  return true;
};

$.fn.dataTable.render.RepositoryDateTimeRangeValueValidator = function($input) {
  const $container = $input.parents('.datetime-container');
  const $dateS = $container.find('.datetime.start');
  const $dateE = $container.find('.datetime.end');
  const $submitField = $container.find('.column-range');
  let isValid = true;
  let errorMessage;
  let startTime;
  let endTime;
  let a = [];

  if ($input.val()) {
    startTime = new Date($dateS.val());
    endTime = new Date($dateE.val());
  }

  a.push($dateS.val() === '');
  a.push($dateE.val() === '');

  if (a.filter((v, i, arr) => arr.indexOf(v) === i).length > 1) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.set_all_or_none');
  } else if (($input.val()) && (startTime > endTime)) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.not_valid_range');
  }

  if (isValid) {
    const oldValue = $submitField.val();
    let newValue;
    if ($dateS.val() && $dateE.val()) {
      newValue = JSON.stringify({ start_time: $dateS.val(), end_time: $dateE.val() });
    }
    if (oldValue !== newValue) {
      $submitField.val(newValue);
    }
    return true;
  }

  $container.find('.date-container').addClass('error');
  $container.find('.date-container').first().attr('data-error-text', errorMessage);
  return false;
};

$.fn.dataTable.render.RepositoryDateRangeValueValidator = function($input) {
  const $container = $input.parents('.datetime-container');
  const $dateS = $container.find('.datetime.start');
  const $dateE = $container.find('.datetime.end');
  const $submitField = $container.find('.column-range');
  let isValid = true;
  let errorMessage;
  let startTime;
  let endTime;

  if ($input.val()) {
    startTime = new Date($dateS.val());
    endTime = new Date($dateE.val());
  }

  if (($dateS.val() === '') !== ($dateE.val() === '')) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.set_all_or_none');
  } else if (($input.val()) && (startTime > endTime)) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.not_valid_range');
  }

  if (isValid) {
    const oldValue = $submitField.val();
    let newValue;
    if ($dateS.val() && $dateE.val()) {
      newValue = JSON.stringify({ start_time: $dateS.val(), end_time: $dateE.val() });
    }
    if (oldValue !== newValue) {
      $submitField.val(newValue);
    }
    return true;
  }

  $container.find('.date-container').addClass('error');
  $container.find('.date-container').first().attr('data-error-text', errorMessage);
  return false;
};

$.fn.dataTable.render.RepositoryTimeRangeValueValidator = function($input) {
  const $container = $input.parents('.datetime-container');
  const $dateS = $container.find('.datetime.start');
  const $dateE = $container.find('.datetime.end');
  const $submitField = $container.find('.column-range');
  let isValid = true;
  let errorMessage;
  let startTime;
  let endTime;

  if ($input.val()) {
    startTime = new Date($dateS.val());
    endTime = new Date($dateE.val());
  }

  if (($dateS.val() === '') !== ($dateE.val() === '')) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.set_all_or_none');
  } else if (endTime < startTime) {
    isValid = false;
    errorMessage = I18n.t('repositories.table.date_time.errors.not_valid_range');
  }
  if (isValid) {
    const oldValue = $submitField.val();
    let newValue;
    if ($dateS.val() && $dateE.val()) {
      newValue = JSON.stringify({ start_time: $dateS.val(), end_time: $dateE.val() });
    }
    if (oldValue !== newValue) {
      $submitField.val(newValue);
    }
    return true;
  }

  $container.find('.date-container').addClass('error');
  $container.find('.date-container').first().attr('data-error-text', errorMessage);
  return false;
};
