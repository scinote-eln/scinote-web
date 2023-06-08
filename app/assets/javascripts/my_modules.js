/* global I18n dropdownSelector HelperModule animateSpinner */
/* eslint-disable no-use-before-define */
(function() {
  const STATUS_POLLING_INTERVAL = 5000;

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
    $('#calendarStartDate').on('dp.change', function() {
      updateStartDate();
    });
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
    $('#calendarDueDate').on('dp.change', function() {
      updateDueDate();
    });
  }

  function checkStatusState() {
    $.getJSON($('.status-flow-dropdown').data('status-check-url'), (statusData) => {
      if (statusData.status_changing) {
        setTimeout(() => { checkStatusState(); }, STATUS_POLLING_INTERVAL);
      } else {
        location.reload();
      }
    });
  }

  function applyTaskStatusChangeCallBack() {
    if ($('.status-flow-dropdown').data('status-changing')) {
      setTimeout(() => { checkStatusState(); }, STATUS_POLLING_INTERVAL);
    }
    $('.task-flows').on('click', '#dropdownTaskFlowList > li[data-state-id]', function() {
      var list = $('#dropdownTaskFlowList');
      var item = $(this);
      animateSpinner();
      $.ajax({
        url: list.data('link-url'),
        beforeSend: function(e, ajaxSettings) {
          if (item.data('beforeSend') instanceof Function) {
            return item.data('beforeSend')(item, ajaxSettings)
          }
          return true
        },
        type: 'PATCH',
        data: { my_module: { status_id: item.data('state-id') } },
        error: function(e) {
          animateSpinner(null, false);
          if (e.status === 403) {
            HelperModule.flashAlertMsg(I18n.t('my_module_statuses.update_status.error.no_permission'), 'danger');
          } else if (e.status === 422) {
            HelperModule.flashAlertMsg(e.responseJSON.errors, 'danger');
          } else {
            HelperModule.flashAlertMsg('error', 'danger');
          }
        }
      });
    });
  }

  function initTagsSelector() {
    var myModuleTagsSelector = '#module-tags-selector';

    dropdownSelector.init($(myModuleTagsSelector), {
      closeOnSelect: true,
      tagClass: 'my-module-white-tags',
      tagStyle: (data) => {
        return `background: ${data.params.color}`;
      },
      customDropdownIcon: () => {
        return '';
      },
      optionLabel: (data) => {
        if (data.value > 0) {
          return `<span class="my-module-tags-color" style="background:${data.params.color}"></span>
                  ${data.label}`;
        }
        return `<span class="my-module-tags-color new"><i class="sn-icon sn-icon-new-task"></i></span>
                  ${data.label + ' '}
                <span class="my-module-tags-create-new"> ${I18n.t('my_modules.details.create_new_tag')}</span>`;
      },
      onOpen: function() {
        $('.select-container .edit-button-container').removeClass('hidden');
      },
      onClose: function() {
        $('.select-container .edit-button-container').addClass('hidden');
      },
      onSelect: function() {
        var selectElement = $(myModuleTagsSelector);
        var lastTag = selectElement.next().find('.ds-tags').last();
        var lastTagId = lastTag.find('.tag-label').data('ds-tag-id');
        var newTag;

        if (lastTagId > 0) {
          newTag = { my_module_tag: { tag_id: lastTagId } };
          $.post(selectElement.data('update-module-tags-url'), newTag)
            .fail(function(response) {
              dropdownSelector.removeValue(myModuleTagsSelector, lastTagId, '', true);
              if (response.status === 403) {
                HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
              }
            });
        } else {
          newTag = {
            tag: {
              name: lastTag.find('.tag-label').html(),
              project_id: selectElement.data('project-id'),
              color: null
            },
            my_module_id: selectElement.data('module-id'),
            simple_creation: true
          };
          $.post(selectElement.data('tags-create-url'), newTag, function(result) {
            dropdownSelector.removeValue(myModuleTagsSelector, 0, '', true);
            dropdownSelector.addValue(myModuleTagsSelector, {
              value: result.tag.id,
              label: result.tag.name,
              params: {
                color: result.tag.color
              }
            }, true);
          }).fail(function() {
            dropdownSelector.removeValue(myModuleTagsSelector, lastTagId, '', true);
          });
        }
      },
      onUnSelect: (id) => {
        $.post(`${$(myModuleTagsSelector).data('update-module-tags-url')}/${id}/destroy_by_tag_id`)
          .success(function() {
            dropdownSelector.closeDropdown(myModuleTagsSelector);
          })
          .fail(function(r) {
            if (r.status === 403) {
              HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
            }
          });
      }
    }).getContainer(myModuleTagsSelector).addClass('my-module-tags-container');
  }


  function initAssignedUsersSelector() {
    var myModuleUserSelector = '#module-assigned-users-selector';

    dropdownSelector.init(myModuleUserSelector, {
      closeOnSelect: true,
      labelHTML: true,
      tagClass: 'my-module-user-tags',
      tagLabel: (data) => {
        return `<img class="img-responsive block-inline" src="${data.params.avatar_url}" alt="${data.label}"/>
                <span style="user-full-name block-inline">${data.label}</span>`;
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
  applyTaskStatusChangeCallBack();
  initTagsSelector();
  initStartDatePicker();
  initDueDatePicker();
  initAssignedUsersSelector();
}());
