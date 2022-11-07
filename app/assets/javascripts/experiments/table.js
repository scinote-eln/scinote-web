/* global I18n GLOBAL_CONSTANTS InfiniteScroll */

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
  let users = '';
  $.each(data.users, (_i, user) => {
    users += `
      <span class="global-avatar-container">
        <img src=${user.image_url} title=${user.title}>
      </span>
    `;
  });

  if (data.length > 3) {
    users += `
    <span class="more-users" title="${data.more_users_title}">
        +${data.length - 3}
    </span>
    `;
  }

  if (data.manage_url) {
    users = `
      <a href="${data.manage_url}" class= 'my-module-users-link', data-action='remote-modal'>
        ${users}
        <span class="new-user global-avatar-container">
          <i class="fas fa-plus"></i>
        </span>
      </a>
    `;
  }

  return users;
};

ExperimnetTable.render.tags = function(data) {
  const value = parseInt(data.tags, 10) === 0 ? I18n.t('experiments.table.add_tag') : data.tags;
  return `<a href="${data.edit_url}" id="myModuleTags${data.my_module_id}" data-remote="true" class="edit-tags-link">${value}</a>`;
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
