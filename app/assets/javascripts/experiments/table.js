/* global GLOBAL_CONSTANTS InfiniteScroll */

const ExperimnetTable = {
  selectedId: [],
  table: '.experiment-table',
  render: {},
  pageSize: GLOBAL_CONSTANTS.DEFAULT_ELEMENTS_PER_PAGE,
  loadPlaceholder: function() {
    let placeholder = '';
    $.each(Array(this.pageSize), function() {
      placeholder += $('#experimentTablePlaceholder').html();
    });
    $(placeholder).insertAfter($(this.table).find('.table-body'));
  },
  appendRows: function(result) {
    $.each(result, (id, data) => {
      // Checkbox selector
      let row = `
        <div class="table-body-cell">
        <div class="sci-checkbox-container">
          <input type="checkbox" class="sci-checkbox">
          <span class="sci-checkbox-label"></span>
        </div>
        </div>`;
      // Task columns
      $.each(data, (_i, cell) => {
        row += `
          <div class="table-body-cell">
            ${ExperimnetTable.render[cell.column_type](cell.data)}
          </div>
        `;
      });
      // Menu
      row += '<div class="table-body-cell"></div>';
      $(`<div class="table-row">${row}</div>`).appendTo(`${this.table} .table-body`);
    });
  },
  init: function() {
    var dataUrl = $(this.table).data('my-modules-url');
    this.loadPlaceholder();
    $.get(dataUrl, (result) => {
      $(this.table).find('.table-row').remove();
      this.appendRows(result.data);
      InfiniteScroll.init(this.table, {
        url: dataUrl,
        eventTarget: window,
        placeholderTemplate: '#experimentTablePlaceholder',
        endOfListTemplate: '#experimentTableEndOfList',
        pageSize: this.pageSize,
        lastPage: !result.next_page,
        customResponse: (response) => {
          this.appendRows(response.data);
        }
      });
    });
  }
};

ExperimnetTable.render.task_name = function(data) {
  return `<a href="${data.url}">${data.name}</a>`;
};

ExperimnetTable.render.id = function(data) {
  return data;
};

ExperimnetTable.render.due_date = function(data) {
  return data;
};

ExperimnetTable.render.age = function(data) {
  return data;
};

ExperimnetTable.render.results = function(data) {
  return `<a href="${data.url}">${data.count}</a>`;
};

ExperimnetTable.render.status = function(data) {
  return `<div class="my-module-status" style="background-color: ${data.color}">${data.name}</div>`;
};

ExperimnetTable.render.assigned = function(data) {
  return data;
};

ExperimnetTable.render.tags = function(data) {
  return data;
};

ExperimnetTable.render.comments = function(data) {
  return data;
};

ExperimnetTable.init();
