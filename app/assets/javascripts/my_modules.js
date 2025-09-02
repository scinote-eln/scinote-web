/* global I18n dropdownSelector HelperModule animateSpinner */
/* eslint-disable no-use-before-define */
(function() {
  function initTaskCollapseState() {
    let taskView = '.my-modules-protocols-index';
    let taskSection = '.task-section-caret';
    let taskId = $(taskView).data('task-id');

    function collapseStateSave() {
      $(taskView).on('click', taskSection, function() {
        let collapsed = $(this).attr('aria-expanded');
        let taskSectionType = $(this).attr('aria-controls');

        if (collapsed === 'true') {
          localStorage.setItem('task_section_collapsed/' + taskId + '/' + taskSectionType, collapsed);
        } else {
          localStorage.removeItem('task_section_collapsed/' + taskId + '/' + taskSectionType);
        }
      });
    }

    function collapseStateLoad() {
      $(taskSection).each(function() {
        let taskSectionType = $(this).attr('aria-controls');
        var collapsed = localStorage.getItem('task_section_collapsed/' + taskId + '/' + taskSectionType);

        if (JSON.parse(collapsed)) {
          $('#' + taskSectionType).collapse('hide');
        }
        $(this).closest('.task-section').removeClass('hidden');
      });
    }

    collapseStateSave();
    collapseStateLoad();
  }

  function updateStartDate() {
    let updateUrl = $('#startDateContainer').data('update-url');
    let val = $('#calendarStartDate').val();
    $.ajax({
      url: updateUrl,
      type: 'PATCH',
      dataType: 'json',
      data: { my_module: { started_on: val } },
      success: function(result) {
        $('#startDateLabelContainer').html(result.start_date_label);
      },
      error: function(response) {
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        }
      }
    });
  }

  // Bind ajax for editing due dates
  function initStartDatePicker() {
    $('.datetime-picker-container#start-date').on('dp:ready', () => {
      $('#calendarStartDate').data('dateTimePicker').onChange = () => {
        updateStartDate();
      };
    });
    if ($('#calendarStartDateContainer').length) {
      window.initDateTimePickerComponent('#calendarStartDateContainer');
    }
  }

  function updateDueDate() {
    let updateUrl = $('#dueDateContainer').data('update-url');
    let val = $('#calendarDueDate').val();
    $.ajax({
      url: updateUrl,
      type: 'PATCH',
      dataType: 'json',
      data: { my_module: { due_date: val } },
      success: function(result) {
        $('#dueDateLabelContainer').html(result.due_date_label);
      },
      error: function(response) {
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        }
      }
    });
  }

  // Bind ajax for editing due dates
  function initDueDatePicker() {
    $('.datetime-picker-container#due-date').on('dp:ready', () => {
      $('#calendarDueDate').data('dateTimePicker').onChange = () => {
        updateDueDate();
      };
    });

    if ($('#calendarDueDateContainer').length) {
      window.initDateTimePickerComponent('#calendarDueDateContainer');
    }
  }




  function initAssignedUsersSelector() {
    var myModuleUserSelector = '#module-assigned-users-selector';

    dropdownSelector.init(myModuleUserSelector, {
      closeOnSelect: true,
      labelHTML: true,
      tagClass: 'my-module-user-tags',
      tagLabel: (data) => {
        return `<img class="img-responsive block-inline" src="${data.params.avatar_url}" alt="${data.label}"/>
                <span class="user-full-name block-inline">${data.label}</span>`;
      },
      customDropdownIcon: () => {
        return '';
      },
      optionLabel: (data) => {
        if (data.params.avatar_url) {
          return `<span class="global-avatar-container" style="margin-top: 10px">
                  <img src="${data.params.avatar_url}" alt="${data.label}"/></span>
                  <span style="margin-left: 10px">${data.label}</span>`;
        }

        return data.label;
      },
      onSelect: function() {
        var selectElement = $(myModuleUserSelector);
        var lastUser = selectElement.next().find('.ds-tags').last();
        var lastUserId = lastUser.find('.tag-label').data('ds-tag-id');
        var newUser;

        if (lastUserId > 0) {
          newUser = {
            user_my_module: {
              user_id: lastUserId
            }
          };
        } else {
          newUser = {
            user_my_module: {
              user_id: selectElement.val()
            }
          };
        }

        $.post(selectElement.data('users-create-url'), newUser, function(result) {
          dropdownSelector.removeValue(myModuleUserSelector, 0, '', true);
          dropdownSelector.addValue(myModuleUserSelector, {
            value: result.user.id,
            label: result.user.full_name,
            params: {
              avatar_url: result.user.avatar_url,
              user_module_id: result.user.user_module_id
            }
          }, true);
        }).fail(function() {
          dropdownSelector.removeValue(myModuleUserSelector, lastUserId, '', true);
        });
      },
      onUnSelect: (id) => {
        var umID = $(myModuleUserSelector).find(`option[value="${id}"]`).data('params').user_module_id;

        $.ajax({
          url: `${$(myModuleUserSelector).data('update-module-users-url')}/${umID}`,
          type: 'DELETE',
          success: () => {
            dropdownSelector.closeDropdown(myModuleUserSelector);
          },
          error: (r) => {
            if (r.status === 403) {
              HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
            }
          }
        });
      }
    }).getContainer(myModuleUserSelector).addClass('my-module-users-container');
  }

  initTaskCollapseState();
  initStartDatePicker();
  initDueDatePicker();
  initAssignedUsersSelector();
}());
