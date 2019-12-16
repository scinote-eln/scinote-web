/* global Inputmask formatJS */
/* eslint-disable no-unused-vars */

var DateTimeHelper = (function() {

  function isValidTimeStr(timeStr) {
    return /^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/.test(timeStr);
  }

  function isValidDate(date) {
    return (Object.prototype.toString.call(date) === '[object Date]') && !isNaN(date.getTime());
  }

  function addLeadingZero(value) {
    return ('0' + value).slice(-2);
  }

  function recalcTimestamp(date, timeStr) {
    if (!isValidTimeStr(timeStr)) {
      date.setHours(0);
      date.setMinutes(0);
      return date;
    }
    let hours = timeStr.split(':')[0];
    let mins = timeStr.split(':')[1];
    date.setHours(hours);
    date.setMinutes(mins);
    return date;
  }

  function stringDateTimeFormat(date, format) {
    let y = date.getFullYear();
    let m = addLeadingZero(date.getMonth() + 1);
    let d = addLeadingZero(date.getDate());
    let hours = addLeadingZero(date.getHours());
    let mins = addLeadingZero(date.getMinutes());

    if (format === 'dateonly') {
      return `${y}/${m}/${d}`;
    }
    return `${y}/${m}/${d} ${hours}:${mins}`;
  }

  function insertHiddenField($input, date, timeStr, format) {
    let formId = $input.data('form-id');
    let columnId = $input.data('column-id');
    let hiddenFieldContainer = $input.parent().find('.cell-timestamp-container');
    let hasTime = isValidTimeStr(timeStr);
    let hasDate = isValidDate(date);
    let value;
    let hiddenField;

    if (!hasDate) { // Date needs to be presence
      value = '';
    } else if (format === 'time' && !hasTime) { // Delete time value
      value = '';
    } else if (format === 'datetime' && !hasTime) { // Delete date time value
      value = '';
    } else {
      // create date time format
      value = stringDateTimeFormat(recalcTimestamp(date, timeStr), 'full');
    }

    hiddenField = `
      <input type="hidden" 
             form="${formId}" 
             name="repository_cells[${columnId}]" 
             value="${value}" />`;

    hiddenFieldContainer.html(hiddenField);
  }

  function initChangeEvents($cell) {
    $cell.find('input[data-mask-type=time]').on('change', function() {
      let timeStr = $(this).val();
      let $container = $(this).parent().find('.cell-timestamp-container');
      let dateStr = $container.data('current-date');
      let columnType = $container.data('datetime-type');
      if (columnType === 'time' && !isValidDate(dateStr)) {
        // new time without value for date
        dateStr = stringDateTimeFormat(new Date(), 'dateonly');
      }

      insertHiddenField($(this), new Date(dateStr), timeStr, columnType);
    });

    $cell.find('.calendar-input').on('dp.change', function(e) {
      let date = e.date._d;
      let timeStr = $(this).parent().find('input[data-mask-type=time]').val();
      let $container = $(this).parent().find('.cell-timestamp-container');

      if (date !== undefined) {
        $container.data('current-date', stringDateTimeFormat(date, 'dateonly'));
      } else {
        $container.data('current-date', '');
      }
      insertHiddenField($(this), date, timeStr, $container.data('datetime-type'));
    });
  }

  function dateInputField(formId, columnId, value) {
    return `
       <input class="form-control editing calendar-input" 
             type="datetime"
             data-form-id="${formId}" 
             data-column-id="${columnId}"
             value='${value}'/>     
    `;
  }

  function timeInputField(formId, columnId, value) {
    return `
      <input class="form-control editing" 
             type="text" 
             data-mask-type="time" 
             data-form-id="${formId}" 
             data-column-id="${columnId}" 
             value='${value}'
             placeholder="HH:mm"/>
    `;
  }

  function initDateEditMode(formId, columnId, $cell, date, datetime) {
    let inputFields = `
    <div class="form-group">
      <div class="cell-timestamp-container" data-current-date="${datetime}" data-datetime-type="date"></div>
      ${dateInputField(formId, columnId, date)}
    </div>
  `;

    $cell.html(inputFields);

    $cell.find('.calendar-input').datetimepicker({ ignoreReadonly: true, locale: 'en', format: formatJS });
    initChangeEvents($cell);
  }

  function initTimeEditMode(formId, columnId, $cell, time, datetime) {
    let inputFields = `
    <div class="form-group">
      <div class="cell-timestamp-container" data-current-date="${datetime}" data-datetime-type="time"></div>
      ${timeInputField(formId, columnId, time)}
    </div>
  `;

    $cell.html(inputFields);

    Inputmask('datetime', {
      inputFormat: 'HH:MM',
      placeholder: 'HH:mm',
      clearIncomplete: true,
      showMaskOnHover: true,
      hourFormat: 24
    }).mask($cell.find('input[data-mask-type="time"]'));

    initChangeEvents($cell);
  }

  function initDateTimeEditMode(formId, columnId, $cell, date, time, datetime) {
    let inputFields = `
    <div class="form-group">
      <div class="cell-timestamp-container" data-current-date="${datetime}" data-datetime-type="datetime"></div>
      ${dateInputField(formId, columnId, date)}
      ${timeInputField(formId, columnId, time)}
    </div>
  `;

    $cell.html(inputFields);

    Inputmask('datetime', {
      inputFormat: 'HH:MM',
      placeholder: 'HH:mm',
      clearIncomplete: true,
      showMaskOnHover: true,
      hourFormat: 24
    }).mask($cell.find('input[data-mask-type="time"]'));

    $cell.find('.calendar-input').datetimepicker({ ignoreReadonly: true, locale: 'en', format: formatJS });
    initChangeEvents($cell);
  }

  return {
    initDateEditMode: initDateEditMode,
    initTimeEditMode: initTimeEditMode,
    initDateTimeEditMode: initDateTimeEditMode,
  };
}());
