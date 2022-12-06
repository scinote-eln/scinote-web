/* global I18n GLOBAL_CONSTANTS InfiniteScroll filterDropdown dropdownSelector HelperModule */

var ExperimnetTable = {
  permissions: ['editable', 'archivable', 'restorable', 'moveable'],
  selectedId: [],
  table: '.experiment-table',
  render: {},
  selectedMyModules: [],
  activeFilters: {},
  filters: [], // Filter {name: '', init(), closeFilter(), apply(), active(), clearFilter()}
  pageSize: GLOBAL_CONSTANTS.DEFAULT_ELEMENTS_PER_PAGE,
  getUrls: function(id) {
    return $(`.table-row[data-id="${id}"]`).data('urls');
  },
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
            <input type="checkbox" class="sci-checkbox my-module-selector" data-my-module="${id}">
            <span class="sci-checkbox-label"></span>
          </div>
        </div>`;
      // Task columns
      $.each(data.columns, (_i, cell) => {
        let hidden = '';
        if ($(`.table-display-modal .fa-eye-slash[data-column="${cell.column_type}"]`).length === 1) {
          hidden = 'hidden';
        }
        row += `
          <div class="table-body-cell ${cell.column_type}-column ${hidden}">
            ${ExperimnetTable.render[cell.column_type](cell.data)}
          </div>
        `;
      });
      // Menu
      row += `
        <div class="table-body-cell">
          <div ref="dropdown" class="dropdown my-module-menu" data-url="${data.urls.actions_dropdown}">
            <div class="btn btn-ligh icon-btn" data-toggle="dropdown" >
              <i class="fas fa-ellipsis-h"></i>
            </div>
            <div class="dropdown-menu dropdown-menu-right">
              <a class="open-access-modal hidden" data-action="remote-modal" href="${data.urls.access}"></a>
            </div>
          </div>
        </div>`;
      $(`<div class="table-row" data-urls='${JSON.stringify(data.urls)}' data-id="${id}">${row}</div>`)
        .appendTo(`${this.table} .table-body`);
    });
  },
  initMyModuleActions: function() {
    $(this.table).on('show.bs.dropdown', '.my-module-menu', (e) => {
      let menu = $(e.target).find('.dropdown-menu');
      $.get(e.target.dataset.url, (result) => {
        $(menu).find('li').remove();
        $(result.html).appendTo(menu);
      });
    });

    $(this.table).on('click', '.archive-my-module', (e) => {
      e.preventDefault();
      this.archiveMyModules(e.target.href, e.target.dataset.id);
    });
  },
  initArchiveMyModules: function() {
    $('#archiveTask').on('click', (e) => {
      this.archiveMyModules(e.target.dataset.url, this.selectedMyModules);
    });
  },
  archiveMyModules: function(url, ids) {
    $.post(url, { my_modules: ids }, (data) => {
      HelperModule.flashAlertMsg(data.message, 'success');
      this.loadTable();
    }).error((data) => {
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
    });
  },
  initAccessModal: function() {
    $('#manageTaskAccess').on('click', () => {
      $(`.table-row[data-id="${this.selectedMyModules[0]}"] .open-access-modal`).click();
    });
  },
  initRenameModal: function() {
    $('#editTask').on('click', () => {
      $('#modal-edit-module').modal('show');
      $('#edit-module-name-input').val($(`#taskName${this.selectedMyModules[0]}`).data('full-name'));
    });
    $('#modal-edit-module').on('click', 'button[data-action="confirm"]', () => {
      let newValue = $('#edit-module-name-input').val();

      if (newValue === $(`#taskName${this.selectedMyModules[0]}`).data('full-name')) {
        $('#modal-edit-module').modal('hide');
        return false;
      }
      $.ajax({
        url: this.getUrls(this.selectedMyModules[0]).name_update,
        type: 'PATCH',
        dataType: 'json',
        data: { my_module: { name: $('#edit-module-name-input').val() } },
        success: () => {
          $(`#taskName${this.selectedMyModules[0]}`).text(newValue);
          $(`#taskName${this.selectedMyModules[0]}`).data('full-name', newValue);
          $('#edit-module-name-input').closest('.sci-input-container').removeClass('error');
          $('#modal-edit-module').modal('hide');
        },
        error: function(response) {
          let error = response.responseJSON.name.join(', ');
          $('#edit-module-name-input')
            .closest('.sci-input-container')
            .addClass('error')
            .attr('data-error-text', error);
        }
      });

      return true;
    });
  },
  initManageUsersDropdown: function() {
    $(this.table).on('show.bs.dropdown', '.assign-users-dropdown', (e) => {
      let usersList = $(e.target).find('.users-list');
      usersList.find('.user-container').remove();
      $.get(usersList.data('list-url'), (result) => {
        $.each(result, (_i, user) => {
          $(`
            <div class="user-container">
              <div class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox user-selector" value="${user.value}">
                <span class="sci-checkbox-label"></span>
              </div>
              <div class="user-avatar">
                <img src="${user.params.avatar_url}"></img>
              </div>
              <div class="user-name">
                ${user.label}
              </div>
            </div>
          `).appendTo(usersList);
        });
      });
    });
  },
  checkActionPermission: function(permission) {
    let allMyModules;

    allMyModules = this.selectedMyModules.every((id) => {
      return $(`.table-row[data-id="${id}"]`).data(permission);
    });

    return allMyModules;
  },
  initSelectAllCheckbox: function() {
    $(this.table).on('click', '.select-all-checkboxes .sci-checkbox', (e1) => {
      $.each($('.my-module-selector'), (_i, e2) => {
        if (e1.target.checked !== e2.checked) e2.click();
      });
    });
  },
  loadPermission: function(id) {
    let row = $(`.table-row[data-id="${id}"]`);
    $.get(this.getUrls(id).permissions, (result) => {
      this.permissions.forEach((permission) => {
        row.data(permission, result[permission]);
      });
      this.updateExperimentToolbar();
    });
  },
  initSelector: function() {
    $(this.table).on('click', '.my-module-selector', (e) => {
      let checkbox = e.target;
      let myModuleId = checkbox.dataset.myModule;
      let index = $.inArray(myModuleId, this.selectedMyModules);

      // If checkbox is checked and row ID is not in list of selected project IDs
      if (checkbox.checked && index === -1) {
        $(checkbox).closest('.table-row').addClass('selected');
        this.selectedMyModules.push(myModuleId);
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        $(checkbox).closest('.table-row').removeClass('selected');
        this.selectedMyModules.splice(index, 1);
      }

      if (checkbox.checked) {
        this.loadPermission(myModuleId);
      } else {
        this.updateExperimentToolbar();
      }
    });
  },
  updateExperimentToolbar: function() {
    let experimentToolbar = $('.toolbar-row');

    if (this.selectedMyModules.length === 0) {
      experimentToolbar.find('.single-object-action, .multiple-object-action').addClass('hidden');
    } else if (this.selectedMyModules.length === 1) {
      experimentToolbar.find('.single-object-action, .multiple-object-action').removeClass('hidden');
    } else {
      experimentToolbar.find('.single-object-action').addClass('hidden');
      experimentToolbar.find('.multiple-object-action').removeClass('hidden');
    }

    this.permissions.forEach((permission) => {
      if (!this.checkActionPermission(permission)) {
        experimentToolbar.find(`.btn[data-for="${permission}"]`).addClass('hidden');
      }
    });

    if ($('#experimentTable').hasClass('archived')) {
      experimentToolbar.find('.only-active').addClass('hidden');
    }
  },
  selectDate: function($field) {
    var datePicker = $field.data('DateTimePicker');
    if (datePicker && datePicker.date()) {
      return datePicker.date()._d.toUTCString();
    }
    return null;
  },
  initManageColumnsModal: function() {
    $.each($('.table-display-modal .fa-eye-slash'), (_i, column) => {
      $(column).parent().removeClass('visible');
    });
    $('.experiment-table')[0].style.setProperty('--columns-count', $('.table-display-modal .fa-eye').length + 1);

    $('.table-display-modal').on('click', '.column-container .fas', (e) => {
      let icon = $(e.target);
      if (icon.hasClass('fa-eye')) {
        $(`.experiment-table .${icon.data('column')}-column`).addClass('hidden');
        icon.removeClass('fa-eye').addClass('fa-eye-slash');
        icon.parent().removeClass('visible');
      } else {
        $(`.experiment-table .${icon.data('column')}-column`).removeClass('hidden');
        icon.addClass('fa-eye').removeClass('fa-eye-slash');
        icon.parent().addClass('visible');
      }

      let visibleColumns = $('.table-display-modal .fa-eye').map((_i, col) => col.dataset.column).toArray();
      // Update columns on backend - $.post('', { columns: visibleColumns }, () => {});
      $.post($('.table-display-modal').data('column-state-url'), { columns: visibleColumns }, () => {});

      $('.experiment-table')[0].style.setProperty('--columns-count', $('.table-display-modal .fa-eye').length + 1);
    });
  },
  initNewTaskModal: function(table) {
    $('.experiment-new-my_module').on('ajax:success', '#new-my-module-modal', function() {
      table.loadTable();
    });
  },
  initFilters: function() {
    this.filterDropdown = filterDropdown.init();
    let $experimentFilter = $('#experimentTable .my-modules-filters');

    $.each(this.filters, (_i, filter) => {
      filter.init($experimentFilter);
    });

    this.filterDropdown.on('filter:apply', () => {
      $.each(this.filters, (_i, filter) => {
        this.activeFilters[filter.name] = filter.apply($experimentFilter);
      });

      filterDropdown.toggleFilterMark(
        this.filterDropdown,
        this.filters.some((filter) => {
          return filter.active(this.activeFilters[filter.name]);
        })
      );

      this.loadTable();
    });

    this.filterDropdown.on('filter:clickBody', () => {
      $.each(this.filters, (_i, filter) => {
        filter.closeFilter($experimentFilter);
      });
    });

    this.filterDropdown.on('filter:clear', () => {
      $.each(this.filters, (_i, filter) => {
        filter.clearFilter($experimentFilter);
      });
    });
  },
  loadTable: function() {
    var dataUrl = $(this.table).data('my-modules-url');
    this.loadPlaceholder();
    $.get(dataUrl, { filters: this.activeFilters }, (result) => {
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
        },
        customParams: (params) => {
          return { ...params, ...{ filters: this.activeFilters } };
        }
      });
    });
  },
  init: function() {
    this.initSelector();
    this.initSelectAllCheckbox();
    this.initFilters();
    this.loadTable();
    this.initRenameModal();
    this.initAccessModal();
    this.initArchiveMyModules();
    this.initManageColumnsModal();
    this.initNewTaskModal(this);
    this.initMyModuleActions();
    this.updateExperimentToolbar();
    this.initManageUsersDropdown();
  }
};

ExperimnetTable.render.task_name = function(data) {
  return `<a href="${data.url}" id="taskName${data.id}" data-full-name="${data.name}">${data.name}</a>`;
};

ExperimnetTable.render.id = function(data) {
  return `
    <div>${data.id}</div>
  `;
};

ExperimnetTable.render.due_date = function(data) {
  return data;
};

ExperimnetTable.render.archived = function(data) {
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

  $.each(data.users, (i, user) => {
    users += `
      <span class="avatar-container" style="z-index: ${5 - i}">
        <img src=${user.image_url} title=${user.title}>
      </span>
    `;
  });

  if (data.count > 4) {
    users += `
    <span class="more-users avatar-container" title="${data.more_users_title}">
        +${data.count - 4}
    </span>
    `;
  }

  if (data.create_url) {
    users += `
      <span class="new-user avatar-container">
        <i class="fas fa-plus"></i>
      </span>
    `;
  }

  return `
    <div ref="dropdown"
         class="assign-users-dropdown dropdown"
    >
      <div class="assigned-users-container" data-toggle="dropdown" >
        ${users}
      </div>
      <div class="dropdown-menu dropdown-menu-right">
        <div class="sci-input-container left-icon">
          <input type="text" class="sci-input-field" placeholder="${I18n.t('experiments.table.search')}"></input>
          <i class="fas fa-search"></i>
        </div>
        <div class="users-list" data-list-url="${data.list_url}">
        </div>
      </div>
    </div>
  `;
};

ExperimnetTable.render.tags = function(data) {
  const value = parseInt(data.tags, 10) === 0 ? I18n.t('experiments.table.add_tag') : data.tags;
  return `<a href="${data.edit_url}"
             id="myModuleTags${data.my_module_id}"
             data-remote="true"
             class="edit-tags-link">${value}</a>`;
};

ExperimnetTable.render.comments = function(data) {
  return `<a href="#"
    class="open-comments-sidebar" id="comment-count-${data.id}"
    data-object-type="MyModule" data-object-id="${data.id}">
      ${data.count > 0 ? data.count : '+'}
      ${data.count_unseen > 0 ? `<span class="unseen-comments"> ${data.count_unseen} </span>` : ''}
  </a>`;
};

// Filters

ExperimnetTable.filters.push({
  name: 'name',
  init: () => {},
  closeFilter: ($container) => {
    $('#textSearchFilterHistory').hide();
    $('#textSearchFilterInput', $container).closest('.dropdown').removeClass('open');
  },
  apply: ($container) => {
    return $('#textSearchFilterInput', $container).val();
  },
  active: (value) => { return value; },
  clearFilter: ($container) => {
    $('#textSearchFilterInput', $container).val('');
  }
});

ExperimnetTable.filters.push({
  name: 'due_date_from',
  init: () => {},
  closeFilter: () => {},
  apply: ($container) => {
    return ExperimnetTable.selectDate($('.due-date-filter .from-date', $container));
  },
  active: (value) => { return value; },
  clearFilter: ($container) => {
    if ($('.due-date-filter .from-date', $container).data('DateTimePicker')) {
      $('.due-date-filter .from-date', $container).data('DateTimePicker').clear();
    }
  }
});

ExperimnetTable.filters.push({
  name: 'due_date_to',
  init: () => {},
  closeFilter: () => {},
  apply: ($container) => {
    return ExperimnetTable.selectDate($('.due-date-filter .to-date', $container));
  },
  active: (value) => { return value; },
  clearFilter: ($container) => {
    if ($('.due-date-filter .to-date', $container).data('DateTimePicker')) {
      $('.due-date-filter .to-date', $container).data('DateTimePicker').clear();
    }
  }
});

ExperimnetTable.filters.push({
  name: 'assigned_users',
  init: ($container) => {
    dropdownSelector.init($('.assigned-filter', $container), {
      optionClass: 'checkbox-icon users-dropdown-list',
      optionLabel: (data) => {
        return `<img class="item-avatar" src="${data.params.avatar_url}"/> ${data.label}`;
      },
      tagLabel: (data) => {
        return `<img class="item-avatar" src="${data.params.avatar_url}"/> ${data.label}`;
      },
      labelHTML: true,
      tagClass: 'users-dropdown-list'
    });
  },
  closeFilter: ($container) => {
    dropdownSelector.closeDropdown($('.assigned-filter', $container));
  },
  apply: ($container) => {
    return dropdownSelector.getValues($('.assigned-filter', $container));
  },
  active: (value) => { return value && value.length !== 0; },
  clearFilter: ($container) => {
    dropdownSelector.clearData($('.assigned-filter', $container));
  }
});

ExperimnetTable.filters.push({
  name: 'statuses',
  init: ($container) => {
    dropdownSelector.init($('.status-filter', $container), {
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple'
    });
  },
  closeFilter: ($container) => {
    dropdownSelector.closeDropdown($('.status-filter', $container));
  },
  apply: ($container) => {
    return dropdownSelector.getValues($('.status-filter', $container));
  },
  active: (value) => { return value && value.length !== 0; },
  clearFilter: ($container) => {
    dropdownSelector.clearData($('.status-filter', $container));
  }
});

ExperimnetTable.init();
