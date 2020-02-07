/* global I18n twemoji */

$.fn.dataTable.render.RepositoryAssetValue = function(data) {
  var asset = data.value;
  return `
    <div class="asset-value-cell">
      ${asset.icon_html}
      <div>
        <a  class="file-preview-link"
          id="modal_link${asset.id}"
          data-no-turbolink="true"
          data-id="true"
          data-status="asset-present"
          data-preview-url="${asset.preview_url}"
          href="${asset.url}"
          >
          ${asset.file_name}
        </a>
      </div>
    </div>
  `;
};

$.fn.dataTable.render.defaultRepositoryAssetValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryTextValue = function(data) {
  return data.value;
};

$.fn.dataTable.render.defaultRepositoryTextValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryListValue = function(data) {
  return `<span data-value-id="${data.value.id}" class="list-label">${data.value.text}</span>`;
};

$.fn.dataTable.render.defaultRepositoryListValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryStatusValue = function(data) {
  return `
  <div class="repository-status-value-container" title="${data.value.icon} ${data.value.status}">
    <span class="repository-status-value-icon">${twemoji.parse(data.value.icon)}</span>
    <span data-value-id="${data.value.id}" class="status-label">${data.value.status}</span>
  </div>
  `;
};

$.fn.dataTable.render.defaultRepositoryStatusValue = function() {
  return '';
};

$.fn.dataTable.render.defaultRepositoryDateValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateValue = function(data) {
  return `<span data-datetime="${data.value.datetime}" data-date="${data.value.formatted}">${data.value.formatted}</span>`;
};

$.fn.dataTable.render.defaultRepositoryDateTimeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateTimeValue = function(data) {
  return `<span data-time="${data.value.time_formatted}"
                data-datetime="${data.value.datetime}"
                data-date="${data.value.date_formatted}">${data.value.formatted}</span>`;
};

$.fn.dataTable.render.defaultRepositoryTimeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryTimeValue = function(data) {
  return `<span data-time="${data.value.formatted}"
                data-datetime="${data.value.datetime}">${data.value.formatted}</span>`;
};

$.fn.dataTable.render.defaultRepositoryTimeRangeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryTimeRangeValue = function(data) {
  return `<span data-time="${data.value.start_time.formatted}"
                data-datetime="${data.value.start_time.datetime}">${data.value.start_time.formatted}</span> -
          <span data-time="${data.value.end_time.formatted}"
                data-datetime="${data.value.end_time.datetime}">${data.value.end_time.formatted}</span>`;
};

$.fn.dataTable.render.defaultRepositoryDateTimeRangeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateTimeRangeValue = function(data) {
  return `<span data-time="${data.value.start_time.time_formatted}"
                data-datetime="${data.value.start_time.datetime}"
                data-date="${data.value.start_time.date_formatted}">${data.value.start_time.formatted}</span> -
          <span data-time="${data.value.end_time.time_formatted}"
                data-datetime="${data.value.end_time.datetime}"
                data-date="${data.value.end_time.date_formatted}">${data.value.end_time.formatted}</span>`;
};

$.fn.dataTable.render.defaultRepositoryDateRangeValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryDateRangeValue = function(data) {
  return `<span data-datetime="${data.value.start_time.datetime}"
                data-date="${data.value.start_time.formatted}">${data.value.start_time.formatted}</span> -
          <span data-datetime="${data.value.end_time.datetime}"
                data-date="${data.value.end_time.formatted}">${data.value.end_time.formatted}</span>`;
};

$.fn.dataTable.render.RepositoryChecklistValue = function(data) {
  var render = '&#8212;';
  var options = data.value;
  var optionsList;
  if (options.length === 1) {
    render = `<span class="checklist-options" data-checklist-items='${JSON.stringify(options)}'>
      ${options[0].label}
    </span>`;
  } else if (options.length > 1) {
    optionsList = $(' <ul class="dropdown-menu checklist-dropdown-menu" role="menu"></ul');
    $.each(options, function(i, option) {
      $(`<li class="checklist-item">${option.label}</li>`).appendTo(optionsList);
    });

    render = `
      <span class="dropdown checklist-dropdown">
        <span data-toggle="dropdown" class="checklist-options" aria-haspopup="true" data-checklist-items='${JSON.stringify(options)}'>
          ${options.length} ${I18n.t('libraries.manange_modal_column.checklist_type.multiple_options')}
        </span>
        ${optionsList[0].outerHTML}
      </span>`;
  }
  return render;
};

$.fn.dataTable.render.defaultRepositoryChecklistValue = function() {
  return '&#8212;';
};

$.fn.dataTable.render.defaultRepositoryNumberValue = function() {
  return '';
};

$.fn.dataTable.render.RepositoryNumberValue = function(data) {
  return `<span class="number-value" data-value="${data.value}">
            ${data.value}
          </span>`;
};
