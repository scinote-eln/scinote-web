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

  function findSecondRangeInput($input) {
    let $container = $input.parent().parent();
    let $secondInput;
    if ($input.parent().hasClass('start-time')) {
      $secondInput = $container.find('.end-time input').first();
    } else {
      $secondInput = $container.find('.start-time input').first();
    }
    return $secondInput;
  }

  function replaceForRangeHiddenField($container) {
    let startTimeContainer = $container.find('.start-time');
    let endTimeContainer = $container.find('.end-time');
    let startTime = startTimeContainer.find('input[type=hidden]').val();
    let endTime = endTimeContainer.find('input[type=hidden]').val();
    let formId = startTimeContainer.find('input[type!=hidden]').data('form-id');
    let columnId = startTimeContainer.find('input[type!=hidden]').data('column-id');
    let dataType = $container.find('.cell-range-container').data('type');
    let json = {};
    let hiddenField;
    let value;

    json.start_time = startTime;
    json.end_time = endTime;

    if (startTime && endTime) {
      value = JSON.stringify(json);
    } else {
      value = '';
    }

    hiddenField = `
      <input type="hidden"
             form="${formId}"
             name="repository_cells[${columnId}]"
             value='${value}'
             data-type="${dataType}"/>`;

    $container.find('.cell-range-container').html(hiddenField);
    startTimeContainer.find('.cell-timestamp-container').html('');
    endTimeContainer.find('.cell-timestamp-container').html('');
  }

  function insertHiddenField($input) {
    let fieldType = $input.data('datetime-part');
    let $container = $input.parent().find('.cell-timestamp-container');
    let dateStr = $container.data('current-date');
    let columnType = $container.data('datetime-type');
    let timeStr;

    if (fieldType === 'time') {
      timeStr = $input.val();
    } else if (fieldType === 'date') {
      timeStr = $input.parent().find('input[data-mask-type=time]').val();
    }

    if (columnType === 'time' && !isValidDate(dateStr)) {
      // new time without value for date
      dateStr = stringDateTimeFormat(new Date(), 'dateonly');
    }
    let date = new Date(dateStr);

    let formId = $input.data('form-id');
    let columnId = $input.data('column-id');
    let hiddenFieldContainer = $input.parent().find('.cell-timestamp-container');
    let hasTime = isValidTimeStr(timeStr);
    let hasDate = isValidDate(date);
    let dataType = $container.data('type');
    let value;
    let hiddenField;

    if (!hasDate) { // Date needs to be presence
      value = '';
    } else if (columnType === 'time' && !hasTime) { // Delete time value
      value = '';
    } else if (columnType === 'datetime' && !hasTime) { // Delete date time value
      value = '';
    } else {
      // create date time format
      value = stringDateTimeFormat(recalcTimestamp(date, timeStr), 'full');
    }

    hiddenField = `
      <input type="hidden" 
             form="${formId}" 
             name="repository_cells[${columnId}]" 
             value="${value}" 
             data-type="${dataType}"/>`;

    hiddenFieldContainer.html(hiddenField);
  }

  function initChangeEvents($cell) {
    $cell.find('input[data-mask-type=time]').on('change', function() {
      let $input = $(this);
      insertHiddenField($input);

      if ($input.parent('.range-type').length) {
        let $secondInput = findSecondRangeInput($input);

        insertHiddenField($secondInput);
        replaceForRangeHiddenField($input.parent().parent());
      }
    });

    $cell.find('.calendar-input').on('dp.change', function(e) {
      let $input = $(this);
      let date = e.date._d;
      let $container = $input.parent().find('.cell-timestamp-container');

      if (date !== undefined) {
        $container.data('current-date', stringDateTimeFormat(date, 'dateonly'));
      } else {
        $container.data('current-date', '');
      }

      insertHiddenField($input);

      if ($input.parent('.range-type').length) {
        let $secondInput = findSecondRangeInput($input);

        insertHiddenField($secondInput);
        replaceForRangeHiddenField($input.parent().parent());
      }
    });
  }

  function dateInputField(formId, columnId, value) {
    return `
       <input class="form-control editing calendar-input" 
             type="datetime"
             data-datetime-part="date"
             data-form-id="${formId}" 
             data-column-id="${columnId}"
             value='${value}'/>     
    `;
  }

  function timeInputField(formId, columnId, value) {
    return `
      <input class="form-control editing" 
             type="text"
             data-datetime-part="time"
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
      <div class="cell-timestamp-container" data-current-date="${datetime}" data-datetime-type="date"  data-type="RepositoryDateValue"></div>
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
      <div class="cell-timestamp-container" data-current-date="${datetime}" data-datetime-type="time"  data-type="RepositoryTimeValue"></div>
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
      <div class="cell-timestamp-container" data-current-date="${datetime}" data-datetime-type="datetime" data-type="RepositoryDateTimeValue"></div>
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

  function initDateTimeRangeEditMode(formId, columnId, $cell, startDate, startTime, startDatetime, endDate, endTime, endDatetime) {
    let inputFields = `
    <div class="form-group">
      <div class="cell-range-container"  data-type="RepositoryDateTimeRangeValue"></div>
      <div class="start-time range-type">
        <div class="cell-timestamp-container" data-current-date="${startDatetime}" data-datetime-type="datetime"></div>
        ${dateInputField(formId, columnId, startDate)}
        ${timeInputField(formId, columnId, startTime)}   
      </div>
      <div class="end-time range-type">
        <div class="cell-timestamp-container" data-current-date="${endDatetime}" data-datetime-type="datetime"></div>
        ${dateInputField(formId, columnId, endDate)}
        ${timeInputField(formId, columnId, endTime)}
      </div>      
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

    let $cal1 = $cell.find('.calendar-input').first().datetimepicker({ ignoreReadonly: true, locale: 'en', format: formatJS });
    let $cal2 = $cell.find('.calendar-input').last().datetimepicker({ ignoreReadonly: true, locale: 'en', format: formatJS });

    $cal1.on('dp.change', function(e) {
      $cal2.data('DateTimePicker').minDate(e.date);
    });
    $cal2.on('dp.change', function(e) {
      $cal1.data('DateTimePicker').maxDate(e.date);
    });

    initChangeEvents($cell);
  }

  function initDateRangeEditMode(formId, columnId, $cell, startDate, startDatetime, endDate, endDatetime) {
    let inputFields = `
    <div class="form-group">
      <div class="cell-range-container" data-type="RepositoryDateRangeValue"></div>
      <div class="start-time range-type">
        <div class="cell-timestamp-container" data-current-date="${startDatetime}" data-datetime-type="date"></div>
        ${dateInputField(formId, columnId, startDate)}
      </div>
      <div class="end-time range-type">
        <div class="cell-timestamp-container" data-current-date="${endDatetime}" data-datetime-type="date"></div>
        ${dateInputField(formId, columnId, endDate)}
      </div>      
    </div>
  `;

    $cell.html(inputFields);

    let $cal1 = $cell.find('.calendar-input').first().datetimepicker({ ignoreReadonly: true, locale: 'en', format: formatJS });
    let $cal2 = $cell.find('.calendar-input').last().datetimepicker({ ignoreReadonly: true, locale: 'en', format: formatJS });

    $cal1.on('dp.change', function(e) {
      $cal2.data('DateTimePicker').minDate(e.date);
    });
    $cal2.on('dp.change', function(e) {
      $cal1.data('DateTimePicker').maxDate(e.date);
    });

    initChangeEvents($cell);
  }

  function initTimeRangeEditMode(formId, columnId, $cell, startTime, startDatetime, endTime, endDatetime) {
    let inputFields = `
    <div class="form-group">
      <div class="cell-range-container" data-type="RepositoryTimeRangeValue"></div>
      <div class="start-time range-type">
        <div class="cell-timestamp-container" data-current-date="${startDatetime}" data-datetime-type="time"></div>
        ${timeInputField(formId, columnId, startTime)}   
      </div>
      <div class="end-time range-type">
        <div class="cell-timestamp-container" data-current-date="${endDatetime}" data-datetime-type="time"></div>
        ${timeInputField(formId, columnId, endTime)}
      </div>      
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

  return {
    initDateEditMode: initDateEditMode,
    initTimeEditMode: initTimeEditMode,
    initDateTimeEditMode: initDateTimeEditMode,
    initDateTimeRangeEditMode: initDateTimeRangeEditMode,
    initDateRangeEditMode: initDateRangeEditMode,
    initTimeRangeEditMode: initTimeRangeEditMode
  };
}());
