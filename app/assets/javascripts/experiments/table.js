/* global I18n GLOBAL_CONSTANTS InfiniteScroll
          initBSTooltips filterDropdown dropdownSelector Sidebar HelperModule notTurbolinksPreview _ */

var ExperimnetTable = {
  selectedId: [],
  table: '.experiment-table',
  tableContainer: '.experiment-table-container',
  selectedMyModules: [],
  activeFilters: {},
  filters: [], // Filter {name: '', init(), closeFilter(), apply(), active(), clearFilter()}
  myModulesCurrentSort: '',
  pageSize: GLOBAL_CONSTANTS.DEFAULT_ELEMENTS_PER_PAGE,
  provisioningStatusTimeout: '',
  render: {
    task_name: function(data) {
      let tooltip = ` title="${_.escape(data.name)}" data-toggle="tooltip" data-placement="bottom"`;
      if (data.provisioning_status === 'in_progress') {
        return `<span data-full-name="${_.escape(data.name)}">${data.name}</span>`;
      }

      return `<a
        href="${data.url}"
        ${tooltip}
        title="${_.escape(data.name)}"
        id="taskName${data.id}"
        data-full-name="${_.escape(data.name)}">${data.name}</a>`;
    },
    id: function(data) {
      return `
        <div>${data.id}</div>
      `;
    },
    due_date: function(data) {
      return data.data;
    },
    archived: function(data) {
      return data;
    },
    age: function(data) {
      return data;
    },
    results: function(data) {
      return `<a href="${data.url}">${data.count}</a>`;
    },
    status: function(data) {
      return `<div class="my-module-status ${data.light_color ? 'status-light' : ''}"
        style="background-color: ${data.color}">${data.name}</div>`;
    },
    assigned: function(data) {
      return data.html;
    },
    tags: function(data) {
      const value = parseInt(data.tags, 10) === 0 ? I18n.t('experiments.table.add_tag') : data.tags;

      if (data.tags === 0 && !data.can_create) {
        return `<span class="disabled">${I18n.t('experiments.table.not_set')}</span>`;
      }

      return `<a href="${data.edit_url}"
                id="myModuleTags${data.my_module_id}"
                data-remote="true"
                class="edit-tags-link">${value}</a>`;
    },
    comments: function(data) {
      if (data.count === 0 && !data.can_create) return '<span class="disabled">0</span>';
      return `<a href="#"
        class="open-comments-sidebar" tabindex=0 id="comment-count-${data.id}"
        data-object-type="MyModule" data-object-id="${data.id}">
          ${data.count > 0 ? data.count : '+'}
          ${data.count_unseen > 0 ? `<span class="unseen-comments"> ${data.count_unseen} </span>` : ''}
      </a>`;
    }
  },
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

        if ($(`.table-display-modal .sn-icon-visibility-hide[data-column="${cell.column_type}"]`).length === 1) {
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
            <div class="btn btn-light btn-xs icon-btn open-my-module-menu" tabindex="0"
                 data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" >
              <i class="sn-icon sn-icon-more-hori"></i>
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

      $(`#calendarDueDateContainer${row.id}`).parent().on('dp:ready', () => {
        $(element).data('dateTimePicker').onChange = () => {
          $.ajax({
            url: dueDateContainer.data('update-url'),
            type: 'PATCH',
            dataType: 'json',
            data: { my_module: { due_date: $(element).val() } },
            success: function(result) {
              dueDateContainer.find('#dueDateLabelContainer').html(result.table_due_date_label.html);
              dateText.data('due-status', result.table_due_date_label.due_status);

              if ($(result.table_due_date_label.html).data('due-date')) {
                clearDate.removeClass('tw-hidden');
              } else {
                clearDate.addClass('tw-hidden');
              }
            }
          });
        }

        clearDate.on('click', () => {
          $(element).data('dateTimePicker').clearDate();
        });
      });

      if ($(`#calendarDueDateContainer${row.id}`).length > 0) {
        window.initDateTimePickerComponent(`#calendarDueDateContainer${row.id}`);
      }
    });
  },
  initMyModuleActions: function() {
    $(this.table).on('show.bs.dropdown', '.my-module-menu', (e) => {
      let menu = $(e.target).find('.dropdown-menu');
      $.get(e.currentTarget.dataset.url, (result) => {
        $(menu).find('li').remove();
        $(result.html).appendTo(menu);
      });
    });

    $(this.table).on('click', '.archive-my-module', (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.archiveMyModules(e.currentTarget.href, e.currentTarget.dataset.id);
    });


    $(this.table).on('click', '.restore-my-module', (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.restoreMyModules(e.currentTarget.href, e.currentTarget.dataset.id);
    });

    $(this.table).on('click', '.duplicate-my-module', (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.duplicateMyModules(e.currentTarget.href, e.currentTarget.dataset.id);
    });

    $(this.table).on('click', '.move-my-module', (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.openMoveModulesModal([e.currentTarget.dataset.id]);
    });

    $(this.table).on('click', '.edit-my-module', (e) => {
      e.preventDefault();
      $('#modal-edit-module').modal('show');
      $('#modal-edit-module').data('id', e.currentTarget.dataset.id);
      $('#edit-module-name-input').val($(`#taskName${$('#modal-edit-module').data('id')}`).data('full-name'));
    });
  },
  initDuplicateMyModules: function() {
    $(this.tableContainer).on('click', '#duplicateTasks', (e) => {
      e.stopPropagation();
      this.duplicateMyModules(e.currentTarget.dataset.url, this.selectedMyModules);
    });
  },
  duplicateMyModules: function(url, ids) {
    $.post(url, { my_module_ids: ids }, () => {
      this.loadTable();
      window.navigatorContainer.reloadChildrenLevel = true;
    }).fail((data) => {
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
    });
  },
  initArchiveMyModules: function() {
    $(this.tableContainer).on('click', '#archiveTask', (e) => {
      e.stopPropagation();
      this.archiveMyModules(e.currentTarget.dataset.url, this.selectedMyModules);
    });
  },
  archiveMyModules: function(url, ids) {
    $.post(url, { my_modules: ids }, (data) => {
      HelperModule.flashAlertMsg(data.message, 'success');
      this.loadTable();
      window.navigatorContainer.reloadChildrenLevel = true;
    }).fail((data) => {
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
    });
  },
  initRestoreMyModules: function() {
    $(this.tableContainer).on('click', '#restoreTask', (e) => {
      e.stopPropagation();
      this.restoreMyModules(e.currentTarget.dataset.url, this.selectedMyModules);
    });
  },
  restoreMyModules: function(url, ids) {
    $.post(url, { my_modules_ids: ids, view: 'table' });
  },
  initRenameModal: function() {
    $(this.tableContainer).on('click', '#editTask', (e) => {
      e.preventDefault();
      $('#modal-edit-module').modal('show');
      $('#modal-edit-module').data('id', this.selectedMyModules[0]);
      $('#edit-module-name-input').val($(`#taskName${$('#modal-edit-module').data('id')}`).data('full-name'));
    });

    const handleRenameModal = () => {
      let id = $('#modal-edit-module').data('id');
      let newValue = $('#edit-module-name-input').val();

      $(`.my-module-selector[data-my-module="${id}"]`).trigger('click');

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

      if ($(`.my-module-selector[data-my-module="${id}"]`).prop('checked')) {
        $(`.my-module-selector[data-my-module="${id}"]`).trigger('click');
      }

      this.clearRowTaskSelection();

      return true;
    };

    $('#modal-edit-module')
      .on('click', 'button[data-action="confirm"]', handleRenameModal)
      .on('submit', 'form', (e) => {
        e.preventDefault();
        handleRenameModal();
      });
  },
  initManageUsersDropdown: function() {
    $(this.table).on('show.bs.dropdown', '.assign-users-dropdown', (e) => {
      setTimeout(() => {
        $('.sci-input-field.user-search').each(function() {
          this.focus();
        });
      }, 200);
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
        e.currentTarget.click();
      }
    });
    $(this.table).on('change keyup', '.assign-users-dropdown .user-search', (e) => {
      let query = e.currentTarget.value;
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
        }).fail((data) => {
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
  initModalInputFocus: function() {
    $(document).on('shown.bs.modal', function() {
      var inputField = $('#edit-module-name-input');
      var value = inputField.val();
      inputField.focus().val('').val(value);
    });
  },
  initMoveModulesModal: function() {
    $(this.tableContainer).on('click', '#moveTask', (e) => {
      e.stopPropagation();
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
          window.navigatorContainer.reloadChildrenLevel = true;
        }).fail((data) => {
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
  updateSelectAllCheckbox: function() {
    const tableWrapper = $(this.table);
    const checkboxesCount = $('.sci-checkbox.my-module-selector', tableWrapper).length;
    const selectedCheckboxesCount = this.selectedMyModules.length;
    const selectAllCheckbox = $('.select-all-checkboxes .sci-checkbox', tableWrapper);

    selectAllCheckbox.prop('indeterminate', false);
    if (selectedCheckboxesCount === 0) {
      selectAllCheckbox.prop('checked', false);
    } else if (selectedCheckboxesCount === checkboxesCount) {
      selectAllCheckbox.prop('checked', true);
    } else {
      selectAllCheckbox.prop('indeterminate', true);
    }
  },
  initSelectAllCheckbox: function() {
    $(this.table).on('click', '.select-all-checkboxes .sci-checkbox', (e1) => {
      $.each($('.my-module-selector'), (_i, e2) => {
        if (e1.target.checked !== e2.checked) e2.click();
      });
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

      this.updateSelectAllCheckbox();
      this.updateExperimentToolbar();
    });
  },
  updateExperimentToolbar: function() {
    if (window.actionToolbarComponent) {
      window.actionToolbarComponent.fetchActions({ my_module_ids: this.selectedMyModules });
    }
  },
  selectDate: function($field) {
    var datePicker = $field.data('dateTimePicker');
    if (datePicker && datePicker.date) {
      return datePicker.date.toString();
    }
    return null;
  },
  initManageColumnsModal: function() {
    $.each($('.table-display-modal .sn-icon-visibility-hide'), (_i, column) => {
      $(column).parent().removeClass('visible');
    });
    $('.experiment-table')[0].style
      .setProperty('--columns-count', $('.table-display-modal .sn-icon-visibility-show:not(.disabled)').length + 1);

    $('.table-display-modal').on('click', '.column-container .sn-icon', (e) => {
      let icon = $(e.target);
      if (icon.hasClass('sn-icon-visibility-show')) {
        $(`.experiment-table .${icon.data('column')}-column`).addClass('hidden');
        icon.removeClass('sn-icon-visibility-show').addClass('sn-icon-visibility-hide');
        icon.parent().removeClass('visible');
      } else {
        if (icon.hasClass('disabled')) return;
        $(`.experiment-table .${icon.data('column')}-column`).removeClass('hidden');
        icon.addClass('sn-icon-visibility-show').removeClass('sn-icon-visibility-hide');
        icon.parent().addClass('visible');
      }

      let visibleColumns = $('.table-display-modal .sn-icon-visibility-show').map((_i, col) => col.dataset.column).toArray();
      // Update columns on backend - $.post('', { columns: visibleColumns }, () => {});
      $.post($('.table-display-modal').data('column-state-url'), { columns: visibleColumns }, () => {});

      $('.experiment-table')[0].style
        .setProperty('--columns-count', $('.table-display-modal .sn-icon-visibility-show:not(.disabled)').length + 1);
    });
  },
  clearRowTaskSelection: function() {
    this.selectedMyModules = [];
    this.updateSelectAllCheckbox();
    this.updateExperimentToolbar();
  },
  initNewTaskModal: function(table) {
    $('.experiment-new-my_module').on('ajax:success', '#new-my-module-modal', function() {
      table.loadTable();
      window.navigatorContainer.reloadChildrenLevel = true;
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
  getFilterValues: function() {
    let $experimentFilter = $('#experimentTable .my-modules-filters');
    $.each(this.filters, (_i, filter) => {
      this.activeFilters[filter.name] = filter.apply($experimentFilter);
    });

    // filters are active if they have any non-empty value
    let filtersEmpty = Object.values(this.activeFilters).every(value => /^\s+$/.test(value)
                                                                                || value === null
                                                                                || value === undefined
                                                                                || (value && value.length === 0));
    this.filtersActive = !filtersEmpty;
  },
  filtersEnabled: function() {
    this.getFilterValues();

    return this.filters.some((filter) => {
      return filter.active(this.activeFilters[filter.name]);
    });
  },
  initFilters: function() {
    let $experimentFilter = $('#experimentTable .my-modules-filters');

    this.filterDropdown = filterDropdown.init(() => this.filtersEnabled());

    $.each(this.filters, (_i, filter) => {
      filter.init($experimentFilter);
    });

    this.filterDropdown.on('filter:apply', () => {
      filterDropdown.toggleFilterMark(this.filterDropdown, this.filtersEnabled());

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

    $.get(dataUrl, tableParams, (result) => {
      $(this.table).find('.table-row-placeholder, .table-row-placeholder-divider').remove();
      setTimeout(() => {
        this.appendRows(result.data);
        this.initDueDatePicker(result.data);
        this.handleNoResults();
        this.initProvisioningStatusPolling();
      }, 100);

      InfiniteScroll.init(this.table, {
        url: dataUrl,
        eventTarget: window,
        placeholderTemplate: '#experimentTablePlaceholder',
        endOfListTemplate: '#experimentTableEndOfList',
        pageSize: this.pageSize,
        lastPage: !result.next_page,
        customResponse: (response) => {
          setTimeout(() => {
            this.appendRows(response.data);
            this.initDueDatePicker(response.data);
            this.initProvisioningStatusPolling();
          }, 100);
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
    $('.no-data-container').hide();
    if (this.filtersActive && tableRowLength === 0) {
      noResultsContainer.style.display = 'block';
    } else if (tableRowLength === 0) {
      $(this.table).find('.table-header').hide();
      $(this.table).addClass('no-data');
      $('.no-data-container').show();
    } else {
      noResultsContainer.style.display = 'none';
      $(this.table).find('.table-header').show();
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
      clearTimeout(this.provisioningStatusTimeout);
      this.provisioningStatusTimeout = setTimeout(() => {
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
    window.initActionToolbar();

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
    this.initModalInputFocus();
  }
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
    $('.due-date-filter .from-date', $container).data('dateTimePicker')?.clearDate();
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
    $('.due-date-filter .to-date', $container).data('dateTimePicker')?.clearDate();
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
    $('.archived-on-filter .from-date', $container).data('dateTimePicker')?.clearDate();
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
    $('.archived-on-filter  .to-date', $container).data('dateTimePicker')?.clearDate();
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
