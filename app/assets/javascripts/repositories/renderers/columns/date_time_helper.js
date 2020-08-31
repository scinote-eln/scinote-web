/* global Inputmask formatJS */
/* eslint-disable no-unused-vars */

var DateTimeHelper = (function() {
  function isValidTimeStr(timeStr) {
    return /^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/.test(timeStr);
  }

  function isValidDate(date) {
    return (date instanceof Date) && !isNaN(date.getTime());
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

    date.setHours(timeStr.split(':')[0]);
    date.setMinutes(timeStr.split(':')[1]);
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

  function insertHiddenField($container) {
    let formId = $container.data('form-id');
    let columnId = $container.data('column-id');
    let dateStr = $container.find('input.date-part').data('selected-date');
    let timeStr = $container.find('input.time-part').val();
    let columnType = $container.data('type');
    let date = new Date(dateStr);
    let value = '';
    let hiddenField;

    if (isValidDate(date) && isValidTimeStr(timeStr)) {
      value = stringDateTimeFormat(recalcTimestamp(date, timeStr), 'full');
    }

    hiddenField = `
      <input class="repository-cell-value"
             type="hidden"
             form="${formId}"
             name="repository_cells[${columnId}]"
             value="${value}"
             data-type="${columnType}"/>`;

    $container.find('input.repository-cell-value').remove();
    $container.prepend(hiddenField);
  }


  function insertRangeHiddenField($container) {
    let formId = $container.data('form-id');
    let columnId = $container.data('column-id');
    let columnType = $container.data('type');
    let $startContainer = $container.find('.start-time');
    let $endContainer = $container.find('.end-time');
    let startDate = new Date($startContainer.find('input.date-part').data('selected-date'));
    let startTimeStr = $startContainer.find('input.time-part').val();
    let endDate = new Date($endContainer.find('input.date-part').data('selected-date'));
    let endTimeStr = $endContainer.find('input.time-part').val();
    let hiddenField;
    let value = '';

    if (isValidDate(startDate)
      && isValidTimeStr(startTimeStr)
      && isValidDate(endDate)
      && isValidTimeStr(endTimeStr)) {
      let start = stringDateTimeFormat(recalcTimestamp(startDate, startTimeStr), 'full');
      let end = stringDateTimeFormat(recalcTimestamp(endDate, endTimeStr), 'full');
      value = JSON.stringify({ start_time: start, end_time: end });
    }

    hiddenField = `
      <input class="repository-cell-value"
             type="hidden"
             form="${formId}"
             name="repository_cells[${columnId}]"
             value='${value}'
             data-type="${columnType}"/>`;

    $container.find('input.repository-cell-value').remove();
    $container.prepend(hiddenField);
  }

  function initChangeEvents($cell) {
    $cell.find('input.time-part').on('change', function() {
      let $input = $(this);
      let $container = $input.closest('.datetime-container');

      if ($container.hasClass('range-type')) {
        insertRangeHiddenField($container);
      } else {
        insertHiddenField($container);
      }
    });

    $cell.find('input.date-part').on('dp.change', function(e) {
      let $input = $(this);
      let date = e.date._d;
      let $container = $input.closest('.datetime-container');

      if (date !== undefined) {
        $input.data('selected-date', stringDateTimeFormat(date, 'dateonly'));
      } else {
        $input.data('selected-date', '');
      }

      if ($container.hasClass('range-type')) {
        insertRangeHiddenField($container);
      } else {
        insertHiddenField($container);
      }
    });
  }


  function dateInputField(value, dateDataValue) {
    return `
      <div class="sci-input-container date-container right-icon">
        <input class="calendar-input date-part sci-input-field"
                type="datetime"
                placeholder="${formatJS}"
                data-datetime-part="date"
                data-selected-date="${dateDataValue}"
                value='${value}'/>
        <i class="fas fa-calendar-alt"></i>
      </div>
    `;
  }

  function timeInputField(value) {
    return `
      <div class="sci-input-container time-container right-icon">
        <input class="time-part sci-input-field"
               type="text"
               data-mask-type="time"
               value='${value}'
               placeholder="HH:mm"/>
        <i class="fas fa-clock"></i>
      </div>
    `;
  }

  function getDateOrDefault($span, mode) {
    let dateStr = $span.data('date');
    let date;
    if (mode === 'timeonly') {
      // Set default date if no data in span
      date = new Date(dateStr);
      if (isValidDate(date)) {
        dateStr = stringDateTimeFormat(new Date(date), 'dateonly');
      } else {
        dateStr = stringDateTimeFormat(new Date(), 'dateonly');
      }
    }
    return dateStr;
  }

  function getTimeOrDefault($span, mode) {
    let timeStr = $span.data('time');

    if ((mode === 'dateonly') && (!isValidTimeStr(timeStr))) {
      timeStr = '00:00';
    }
    return timeStr;
  }

  function initCurrentTimeSelector($cell) {
    $cell.find('.time-container .fa-clock').click(function() {
      var inputField = $(this).prev();
      var d = new Date();
      var h = addLeadingZero(d.getHours());
      var m = addLeadingZero(d.getMinutes());
      inputField.val(h + ':' + m).change();
    });
  }

  function initDateTimeEditMode(formId, columnId, $cell, mode, columnType) {
    let $span = $cell.find('span').first();
    let date = $span.data('date');
    let dateDataValue = getDateOrDefault($span, mode);
    let time = getTimeOrDefault($span, mode);
    let datetime = $span.data('datetime');
    let inputFields = `
    <div class="form-group datetime-container ${mode}"
                data-form-id="${formId}"
                data-column-id="${columnId}"
                data-type="${columnType}"
                data-current-datetime="${datetime}">
      ${dateInputField(date, dateDataValue)}
      ${timeInputField(time)}
    </div>
  `;

    $cell.html(inputFields);
    initCurrentTimeSelector($cell);

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

  function initDateTimeRangeEditMode(formId, columnId, $cell, mode, columnType) {
    let $startSpan = $cell.find('span').first();
    let startDate = $startSpan.data('date');
    let startTime = getTimeOrDefault($startSpan, mode);
    let startDatetime = $startSpan.data('datetime');
    let startDateDataValue = getDateOrDefault($startSpan, mode);
    let $endSpan = $cell.find('span').last();
    let endDate = $endSpan.data('date');
    let endTime = getTimeOrDefault($endSpan, mode);
    let endDatetime = $endSpan.data('datetime');
    let endDateDataValue = getDateOrDefault($endSpan, mode);

    let inputFields = `
    <div class="form-group datetime-container range-type"
         data-form-id="${formId}"
         data-column-id="${columnId}"
         data-type="${columnType}"
         >
      <div class="start-time ${mode}"
           data-current-datetime="${startDatetime}">
        ${dateInputField(startDate, startDateDataValue)}
        ${timeInputField(startTime)}
      </div>
      <div class="separator">—</div>
      <div class="end-time ${mode}"
           data-current-datetime="${endDatetime}">
        ${dateInputField(endDate, endDateDataValue)}
        ${timeInputField(endTime)}
      </div>
    </div>
  `;

    $cell.html(inputFields);
    initCurrentTimeSelector($cell);

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

  return {
    initDateTimeEditMode: initDateTimeEditMode,
    initDateTimeRangeEditMode: initDateTimeRangeEditMode
  };
}());
