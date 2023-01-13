/* global I18n GLOBAL_CONSTANTS InfiniteScroll
          initBSTooltips filterDropdown dropdownSelector Sidebar HelperModule notTurbolinksPreview */

var ExperimnetTable = {
  permissions: ['editable', 'archivable', 'restorable', 'moveable'],
  selectedId: [],
  table: '.experiment-table',
  render: {},
  selectedMyModules: [],
  activeFilters: {},
  filters: [], // Filter {name: '', init(), closeFilter(), apply(), active(), clearFilter()}
  myModulesCurrentSort: '',
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
    $.each(result, (_j, data) => {
      let row;
      const isProvisioning = data.provisioning_status === 'in_progress';
      const provisioningTooltipAttrs = `title="${I18n.t('experiments.duplicate_tasks.duplicating')}"
        data-toggle="tooltip"`;

      // Checkbox selector
      row = `
            <div class="table-body-cell">
              <div class="sci-checkbox-container">
                <div title="${I18n.t('experiments.duplicate_tasks.duplicating')}"
                  class="loading-overlay" data-toggle="tooltip" data-placement="right"></div>
                <input type="checkbox" class="sci-checkbox my-module-selector" data-my-module="${data.id}">
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
          <div class="table-body-cell ${cell.column_type}-column ${hidden}"
            ${cell.column_type === 'task_name' && isProvisioning ? provisioningTooltipAttrs : ''}>
            ${ExperimnetTable.render[cell.column_type](cell.data)}
          </div>
        `;
      });
      // Menu
      row += `
        <div class="table-body-cell">
          <div ref="dropdown" class="dropdown my-module-menu" data-url="${data.urls.actions_dropdown}">
            <div class="btn btn-ligh icon-btn open-my-module-menu" tabindex="0"
                 data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" >
              <i class="fas fa-ellipsis-h"></i>
            </div>
            <div class="dropdown-menu dropdown-menu-right">
              <a class="open-access-modal hidden" data-action="remote-modal" href="${data.urls.access}"></a>
            </div>
          </div>
        </div>`;

      let tableRowClass = `table-row ${isProvisioning ? 'table-row-provisioning' : ''}`;
      $(`<div class="${tableRowClass}" data-urls='${JSON.stringify(data.urls)}' data-id="${data.id}">${row}</div>`)
        .appendTo(`${this.table} .table-body`);
    });
  },
  initDueDatePicker: function(data) {
    // eslint-disable-next-line no-unused-vars
    $.each(data, (_, row) => {
      let element = `#calendarDueDate${row.id}`;
      let dueDateContainer = $(element).closest('#dueDateContainer');
      let dateText = $(element).closest('.date-text');
      let clearDate = $(element).closest('.datetime-container').find('.clear-date');

      $(element).on('dp.change', function() {
        $.ajax({
          url: dueDateContainer.data('update-url'),
          type: 'PATCH',
          dataType: 'json',
          data: { my_module: { due_date: $(element).val() } },
          success: function(result) {
            dueDateContainer.find('#dueDateLabelContainer').html(result.table_due_date_label.html);
            dateText.data('due-status', result.table_due_date_label.due_status);

            if ($(result.table_due_date_label.html).data('due-date')) {
              clearDate.addClass('open');
            }
          }
        });
      });

      $(element).on('dp.hide', function() {
        dateText.attr('data-original-title', dateText.data('due-status'));
        clearDate.removeClass('open');
      });

      $(element).on('dp.show', function() {
        var datePicker = $('.bootstrap-datetimepicker-widget.dropdown-menu')[0];

        // show full datepicker menu for due date
        if (datePicker.getBoundingClientRect().bottom > window.innerHeight) {
          datePicker.scrollIntoView(false);
        } else if (datePicker.getBoundingClientRect().top < 0) {
          datePicker.scrollIntoView();
        }

        dateText.attr('data-original-title', '').tooltip('hide');
        if (dueDateContainer.find('.due-date-label').data('due-date')) {
          clearDate.addClass('open');
        }
      });
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


    $(this.table).on('click', '.restore-my-module', (e) => {
      e.preventDefault();
      this.restoreMyModules(e.target.href, e.target.dataset.id);
    });

    $(this.table).on('click', '.duplicate-my-module', (e) => {
      e.preventDefault();
      this.duplicateMyModules($('#duplicateTasks').data('url'), e.target.dataset.id);
    });

    $(this.table).on('click', '.move-my-module', (e) => {
      e.preventDefault();
      this.openMoveModulesModal([e.target.dataset.id]);
    });

    $(this.table).on('click', '.edit-my-module', (e) => {
      e.preventDefault();
      $('#modal-edit-module').modal('show');
      $('#modal-edit-module').data('id', e.target.dataset.id);
      $('#edit-module-name-input').val($(`#taskName${$('#modal-edit-module').data('id')}`).data('full-name'));
    });
  },
  initDuplicateMyModules: function() {
    $('#duplicateTasks').on('click', (e) => {
      this.duplicateMyModules(e.target.dataset.url, this.selectedMyModules);
    });
  },
  duplicateMyModules: function(url, ids) {
    $.post(url, { my_module_ids: ids }, () => {
      this.loadTable();
    }).error((data) => {
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
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
  initRestoreMyModules: function() {
    $('#restoreTask').on('click', (e) => {
      this.restoreMyModules(e.target.dataset.url, this.selectedMyModules);
    });
  },
  restoreMyModules: function(url, ids) {
    $.post(url, { my_modules_ids: ids, view: 'table' });
  },
  initRenameModal: function() {
    $('#editTask').on('click', () => {
      $('#modal-edit-module').modal('show');
      $('#modal-edit-module').data('id', this.selectedMyModules[0]);
      $('#edit-module-name-input').val($(`#taskName${$('#modal-edit-module').data('id')}`).data('full-name'));
    });
    $('#modal-edit-module').on('click', 'button[data-action="confirm"]', () => {
      let id = $('#modal-edit-module').data('id');
      let newValue = $('#edit-module-name-input').val();

      $(`.my-module-selector[data-my-module="${id}"]`).click();

      if (newValue === $(`#taskName${id}`).data('full-name')) {
        $('#modal-edit-module').modal('hide');
        return false;
      }
      $.ajax({
        url: this.getUrls(id).name_update,
        type: 'PATCH',
        dataType: 'json',
        data: { my_module: { name: $('#edit-module-name-input').val() } },
        success: () => {
          $(`#taskName${id}`).text(newValue);
          $(`#taskName${id}`).data('full-name', newValue);
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
      let isArchivedView = $('#experimentTable').hasClass('archived');
      let viewOnly = $(e.target).data('view-only');
      let checkbox = '';
      usersList.find('.user-container').remove();
      $.get(usersList.data('list-url'), (result) => {
        $.each(result, (_i, user) => {
          if (!isArchivedView && !viewOnly) {
            checkbox = `<div class="sci-checkbox-container">
                          <input type="checkbox"
                                class="sci-checkbox user-selector"
                                ${user.params.designated ? 'checked' : ''}
                                value="${user.value}"
                                data-assign-url="${user.params.assign_url}"
                                data-unassign-url="${user.params.unassign_url}"
                          >
                          <span class="sci-checkbox-label"></span>
                        </div>`;
          }

          $(`
            <div class="user-container">
              ${checkbox}
              <div class="user-avatar ${isArchivedView ? 'archived' : ''}">
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
    $(this.table).on('click', '.assign-users-dropdown .dropdown-menu', (e) => {
      if (e.target.tagName === 'INPUT') return;
      e.preventDefault();
      e.stopPropagation();
    });
    $(this.table).on('keyup', '.assigned-users-container, .open-my-module-menu, .calendar-input', (e) => {
      if (e.keyCode === 13) { // Enter
        e.target.click();
      }
    });
    $(this.table).on('change keyup', '.assign-users-dropdown .user-search', (e) => {
      let query = e.target.value;
      let usersList = $(e.target).closest('.dropdown-menu').find('.user-container');
      $.each(usersList, (_i, user) => {
        $(user).removeClass('hidden');
        if (query.length && !$(user).find('.user-name').text().toLowerCase()
          .includes(query.toLowerCase())) {
          $(user).addClass('hidden');
        }
      });
    });
    $(this.table).on('change', '.assign-users-dropdown .user-selector', (e) => {
      let checkbox = e.target;
      if (checkbox.checked) {
        $.post(checkbox.dataset.assignUrl, {
          table: true,
          user_my_module: {
            my_module_id: $(checkbox).closest('.table-row').data('id'),
            user_id: checkbox.value
          }
        }, (result) => {
          checkbox.dataset.unassignUrl = result.unassign_url;
          $(checkbox).closest('.table-row').find('.assigned-users-container')
            .replaceWith($(result.html).find('.assigned-users-container'));
        }).error((data) => {
          HelperModule.flashAlertMsg(data.responseJSON.errors, 'danger');
        });
      } else {
        $.ajax({
          url: checkbox.dataset.unassignUrl,
          method: 'DELETE',
          data: { table: true },
          success: (result) => {
            $(checkbox).closest('.table-row').find('.assigned-users-container')
              .replaceWith($(result.html).find('.assigned-users-container'));
          },
          error: (data) => {
            HelperModule.flashAlertMsg(data.responseJSON.errors, 'danger');
          }
        });
      }
    });
  },
  initMoveModulesModal: function() {
    $('#moveTask').on('click', () => {
      this.openMoveModulesModal(this.selectedMyModules);
    });
  },
  openMoveModulesModal: function(ids) {
    let table = $(this.table);
    $.get(table.data('move-modules-modal-url'), (modalData) => {
      if ($('#modal-move-modules').length > 0) {
        $('#modal-move-modules').replaceWith(modalData.html);
      } else {
        $('#experimentTable').append(modalData.html);
      }
      $('#modal-move-modules').on('shown.bs.modal', function() {
        $(this).find('.selectpicker').selectpicker().focus();
      });
      $('#modal-move-modules').on('click', 'button[data-action="confirm"]', () => {
        let moveParams = {
          to_experiment_id: $('#modal-move-modules').find('.selectpicker').val(),
          my_module_ids: ids
        };
        $.post(table.data('move-modules-url'), moveParams, (data) => {
          HelperModule.flashAlertMsg(data.message, 'success');
          this.loadTable();
        }).error((data) => {
          HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
        });
        $('#modal-move-modules').modal('hide');
      });
      $('#modal-move-modules').modal('show');
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
    $('.experiment-table')[0].style
      .setProperty('--columns-count', $('.table-display-modal .fa-eye:not(.disabled)').length + 1);

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

      $('.experiment-table')[0].style
        .setProperty('--columns-count', $('.table-display-modal .fa-eye:not(.disabled)').length + 1);
    });
  },
  clearRowTaskSelection: function() {
    this.selectedMyModules = [];
    $('.select-all-checkboxes .sci-checkbox').prop('checked', false);
    this.updateExperimentToolbar();
  },
  initNewTaskModal: function(table) {
    $('.experiment-new-my_module').on('ajax:success', '#new-my-module-modal', function() {
      table.loadTable();
    });
  },
  initSorting: function(table) {
    $('#sortMenuDropdown a').click(function() {
      if (table.myModulesCurrentSort !== $(this).data('sort')) {
        $('#sortMenuDropdown a').removeClass('selected');
        // eslint-disable-next-line no-param-reassign
        table.myModulesCurrentSort = $(this).data('sort');
        table.loadTable();
        $(this).addClass('selected');
        $('#sortMenu').dropdown('toggle');
      }
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
      
      // filters are active if they have any non-empty value
      let filtersEmpty = Object.values(this.activeFilters).every(value => /^\s+$/.test(value) || value === null || value === undefined || value && value.length === 0);
      this.filtersActive = !filtersEmpty;

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
    var tableParams = {
      filters: this.activeFilters,
      sort: this.myModulesCurrentSort
    };
    var dataUrl = $(this.table).data('my-modules-url');
    $(this.table).find('.table-row').remove();
    this.loadPlaceholder();

    Sidebar.reload({
      sort: this.myModulesCurrentSort,
      view_mode: $('#experimentTable').hasClass('archived') ? 'archived' : ''
    });

    $.get(dataUrl, tableParams, (result) => {
      $(this.table).find('.table-row-placeholder, .table-row-placeholder-divider').remove();
      this.appendRows(result.data);
      this.initDueDatePicker(result.data);
      this.handleNoResults();

      InfiniteScroll.init(this.table, {
        url: dataUrl,
        eventTarget: window,
        placeholderTemplate: '#experimentTablePlaceholder',
        endOfListTemplate: '#experimentTableEndOfList',
        pageSize: this.pageSize,
        lastPage: !result.next_page,
        customResponse: (response) => {
          this.appendRows(response.data);
          this.initDueDatePicker(response.data);
        },
        customParams: (params) => {
          return { ...params, ...tableParams };
        }
      });

      initBSTooltips();
      this.clearRowTaskSelection();
      this.initProvisioningStatusPolling();
    });
  },
  initProvisioningStatusPolling: function() {
    let provisioningStatusUrls = $('.table-row-provisioning').toArray()
      .map((u) => $(u).data('urls').provisioning_status)
      .filter((u) => !!u);

    this.provisioningMyModulesCount = provisioningStatusUrls.length;

    if (this.provisioningMyModulesCount > 0) this.pollProvisioningStatuses(provisioningStatusUrls);
  },
  handleNoResults: function() {
    let tableRowLength = document.getElementsByClassName('table-row').length;
    let noResultsContainer = document.getElementById('tasksNoResultsContainer');
    if (this.filtersActive && tableRowLength === 0) {
      noResultsContainer.style.display = 'block';
    } else {
      noResultsContainer.style.display = 'none';
    }
  },
  pollProvisioningStatuses: function(provisioningStatusUrls) {
    let remainingUrls = [];

    provisioningStatusUrls.forEach((url) => {
      jQuery.ajax({
        url: url,
        success: (data) => {
          if (data.provisioning_status === 'in_progress') remainingUrls.push(url);
        },
        async: false
      });
    });

    if (remainingUrls.length > 0) {
      setTimeout(() => {
        this.pollProvisioningStatuses(remainingUrls);
      }, 10000);
    } else {
      HelperModule.flashAlertMsg(
        I18n.t('experiments.duplicate_tasks.success', { count: this.provisioningMyModulesCount }),
        'success'
      );
      this.loadTable();
    }
  },
  init: function() {
    this.initSelector();
    this.initSelectAllCheckbox();
    this.initFilters();
    this.initSorting(this);
    this.loadTable();
    this.initRenameModal();
    this.initDuplicateMyModules();
    this.initMoveModulesModal();
    this.initArchiveMyModules();
    this.initManageColumnsModal();
    this.initNewTaskModal(this);
    this.initMyModuleActions();
    this.initRestoreMyModules();
    this.initManageUsersDropdown();
  }
};

ExperimnetTable.render.task_name = function(data) {
  let tooltip = ` title="${data.name}" data-toggle="tooltip" data-placement="bottom"`;
  if (data.provisioning_status === 'in_progress') {
    return `<span data-full-name="${data.name}">${data.name}</span>`;
  }

  return `<a
    href="${data.url}"
    ${tooltip}
    title="${data.name}"
    id="taskName${data.id}"
    data-full-name="${data.name}">${data.name}</a>`;
};

ExperimnetTable.render.id = function(data) {
  return `
    <div>${data.id}</div>
  `;
};

ExperimnetTable.render.due_date = function(data) {
  return data.data;
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
  return data.html;
};

ExperimnetTable.render.tags = function(data) {
  const value = parseInt(data.tags, 10) === 0 ? I18n.t('experiments.table.add_tag') : data.tags;

  if (data.tags === 0 && !data.can_create) {
    return `<span class="disabled">${I18n.t('experiments.table.not_set')}</span>`;
  }

  return `<a href="${data.edit_url}"
             id="myModuleTags${data.my_module_id}"
             data-remote="true"
             class="edit-tags-link">${value}</a>`;
};

ExperimnetTable.render.comments = function(data) {
  if (data.count === 0 && !data.can_create) return '<span class="disabled">0</span>';
  return `<a href="#"
    class="open-comments-sidebar" tabindex=0 id="comment-count-${data.id}"
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
  name: 'archived_on_from',
  init: () => {},
  closeFilter: () => {},
  apply: ($container) => {
    return ExperimnetTable.selectDate($('.archived-on-filter .from-date', $container));
  },
  active: (value) => { return value; },
  clearFilter: ($container) => {
    if ($('.archived-on-filter .from-date', $container).data('DateTimePicker')) {
      $('.archived-on-filter .from-date', $container).data('DateTimePicker').clear();
    }
  }
});

ExperimnetTable.filters.push({
  name: 'archived_on_to',
  init: () => {},
  closeFilter: () => {},
  apply: ($container) => {
    return ExperimnetTable.selectDate($('.archived-on-filter  .to-date', $container));
  },
  active: (value) => { return value; },
  clearFilter: ($container) => {
    if ($('.archived-on-filter .to-date', $container).data('DateTimePicker')) {
      $('.archived-on-filter  .to-date', $container).data('DateTimePicker').clear();
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

if (notTurbolinksPreview()) {
  ExperimnetTable.init();
}
