const ExperimnetTable = {
  selectedId: [],
  table: '.experiment-table',
  render: {},
  init: function() {
    $.get($('.experiment-table').data('my-modules-url'), (result) => {
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
  return `<a href="#" 
    class="open-comments-sidebar" id="comment-count-${data.id}" 
    data-object-type="MyModule" data-object-id="${data.id}">
      ${data.count > 0 ? data.count : '+'}
      ${data.count_unseen > 0 ? `<span class="unseen-comments"> ${data.count_unseen} </span>` : ''}
  </a>`;
};

ExperimnetTable.init();
