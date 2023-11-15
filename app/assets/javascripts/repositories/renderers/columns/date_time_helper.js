/* global Inputmask formatJS */
/* eslint-disable no-unused-vars */

var DateTimeHelper = (function() {
  function placeholder(mode) {
    if (mode === 'date') return formatJS;
    if (mode === 'time') return 'HH:mm';
    return `${formatJS} HH:mm`;
  }

  function initDateTimeEditMode(formId, columnId, $cell, mode, columnType) {
    const $span = $cell.find('span').first();
    const dateTime = $span.data('datetime') || '';
    const inputFields = `
      <div class="datetime-container">
        <div id="datetimePickerContainer${formId}${columnId}"
             class="date-container ${mode} vue-date-time-picker-filter min-w-[160px]">
          <input ref="input"
                data-type="${columnType}"
                data-simple-format="true"
                form="${formId}"
                name="repository_cells[${columnId}]"
                class="datetime" type="hidden"
                data-default="${dateTime}"
                v-model="date"
                id="datetimePicker${formId}${columnId}" />
          <date-time-picker class="w-full" @cleared="clearDate"
                            :teleport="false"
                            :clearable="true"
                            ref="vueDateTime" @change="updateDate" mode="${mode}"
                            placeholder="${placeholder(mode)}"></date-time-picker>
        </div>
      </div>
    `;

    $cell.html(inputFields);

    window.initDateTimePickerComponent(`#datetimePickerContainer${formId}${columnId}`);
  }

  function initDateTimeRangeEditMode(formId, columnId, $cell, mode, columnType) {
    const $startSpan = $cell.find('span').first();
    const startDateTime = $startSpan.data('datetime') || '';
    const $endSpan = $cell.find('span').last();
    const endDateTime = $endSpan.data('datetime') || '';


    const inputFields = `
    <div class="datetime-container range-type ${mode}">
        <input type="hidden" form="${formId}" class="column-range" name="repository_cells[${columnId}]"
          value='${JSON.stringify({ start_time: startDateTime, end_time: endDateTime })}'>
        <div id="datetimeStartPickerComtainer${formId}${columnId}"
             class="date-container ${mode} vue-date-time-picker-filter min-w-[160px]">
          <input ref="input"
                data-type="${columnType}"
                data-simple-format="true"
                form="${formId}"
                class="datetime start" type="hidden"
                data-default="${startDateTime}"
                v-model="date"
                id="datetimeStartPicker${formId}${columnId}" />
          <date-time-picker class="w-full" @cleared="clearDate"
                            :teleport="false"
                            :clearable="true"
                            ref="vueDateTime" @change="updateDate"
                            mode="${mode}" placeholder="${placeholder(mode)}"></date-time-picker>
        </div>
        <div class="separator">—</div>
        <div id="datetimeEndPickerComtainer${formId}${columnId}"
             class="date-container ${mode} vue-date-time-picker-filter min-w-[160px]">
          <input ref="input"
                data-type="${columnType}"
                data-simple-format="true"
                form="${formId}"
                class="datetime end" type="hidden"
                data-default="${endDateTime}"
                v-model="date"
                id="datetimeEndPicker${formId}${columnId}" />
          <date-time-picker class="w-full" @cleared="clearDate"
                            :teleport="false"
                            :clearable="true"
                            ref="vueDateTime" @change="updateDate" mode="${mode}"
                            placeholder="${placeholder(mode)}"></date-time-picker>
        </div>
      </div>`;
    $cell.html(inputFields);
    window.initDateTimePickerComponent(`#datetimeStartPickerComtainer${formId}${columnId}`);
    window.initDateTimePickerComponent(`#datetimeEndPickerComtainer${formId}${columnId}`);
  }

  return {
    initDateTimeEditMode: initDateTimeEditMode,
    initDateTimeRangeEditMode: initDateTimeRangeEditMode
  };
}());
