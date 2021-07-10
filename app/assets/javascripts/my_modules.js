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


  // Bind ajax for editing tags
  function bindEditTagsAjax() {
    var manageTagsModal = null;
    var manageTagsModalBody = null;

    // Initialize reloading of manage tags modal content after posting new
    // tag.
    function initAddTagForm() {
      manageTagsModalBody.find('.add-tag-form')
        .submit(function() {
          var selectOptions = manageTagsModalBody.find('#new_my_module_tag .dropdown-menu li').length;
          if (selectOptions === 0 && this.id === 'new_my_module_tag') return false;
          return true;
        })
        .on('ajax:success', function(e, data) {
          var newTag;
          initTagsModalBody(data);
          newTag = $('#manage-module-tags-modal .list-group-item').last();
          dropdownSelector.addValue('#module-tags-selector', {
            value: newTag.data('tag-id'),
            label: newTag.data('name'),
            params: {
              color: newTag.data('color')
            }
          }, true);
        });
    }

    // Initialize edit tag & remove tag functionality from my_module links.
    function initTagRowLinks() {
      manageTagsModalBody.find('.edit-tag-link')
        .on('click', function() {
          var $this = $(this);
          var li = $this.parents('li.list-group-item');
          var editDiv = $(li.find('div.tag-edit'));

          // Revert all rows to their original states
          manageTagsModalBody.find('li.list-group-item').each(function() {
            var li2 = $(this);
            li2.css('background-color', li2.data('color'));
            li2.find('.edit-tag-form').clearFormErrors();
            li2.find('input[type=text]').val(li2.data('name'));
          });

          // Hide all other edit divs, show all show divs
          manageTagsModalBody.find('div.tag-edit').hide();
          manageTagsModalBody.find('div.tag-show').show();

          editDiv.find('input[type=text]').val(li.data('name'));
          editDiv.find('.edit-tag-color').colorselector('setColor', li.data('color'));

          li.find('div.tag-show').hide();
          editDiv.show();
        });
      manageTagsModalBody.find('div.tag-edit .dropdown-colorselector > .dropdown-menu li a')
        .on('click', function() {
          // Change background of the <li>
          var $this = $(this);
          var li = $this.parents('li.list-group-item');
          li.css('background-color', $this.data('value'));
        });
      manageTagsModalBody.find('.remove-tag-link')
        .on('ajax:success', function(e, data) {
          dropdownSelector.removeValue('#module-tags-selector', this.dataset.tagId, '', true);
          initTagsModalBody(data);
        });
      manageTagsModalBody.find('.delete-tag-form')
        .on('ajax:success', function(e, data) {
          dropdownSelector.removeValue('#module-tags-selector', this.dataset.tagId, '', true);
          initTagsModalBody(data);
        });
      manageTagsModalBody.find('.edit-tag-form')
        .on('ajax:success', function(e, data) {
          var newTag;
          initTagsModalBody(data);
          dropdownSelector.removeValue('#module-tags-selector', this.dataset.tagId, '', true);
          newTag = $('#manage-module-tags-modal .list-group-item[data-tag-id=' + this.dataset.tagId + ']');
          dropdownSelector.addValue('#module-tags-selector', {
            value: newTag.data('tag-id'),
            label: newTag.data('name'),
            params: {
              color: newTag.data('color')
            }
          }, true);
        })
        .on('ajax:error', function(e, data) {
          $(this).renderFormErrors('tag', data.responseJSON);
        });
      manageTagsModalBody.find('.cancel-tag-link')
        .on('click', function() {
          var $this = $(this);
          var li = $this.parents('li.list-group-item');

          li.css('background-color', li.data('color'));
          li.find('.edit-tag-form').clearFormErrors();

          li.find('div.tag-edit').hide();
          li.find('div.tag-show').show();
        });
    }

    // Initialize ajax listeners and elements style on modal body. This
    // function must be called when modal body is changed.
    function initTagsModalBody(data) {
      manageTagsModalBody.html(data.html);
      manageTagsModalBody.find('.selectpicker').selectpicker();
      initAddTagForm();
      initTagRowLinks();
    }

    manageTagsModal = $('#manage-module-tags-modal');
    manageTagsModalBody = manageTagsModal.find('.modal-body');

    // Reload tags HTML element when modal is closed
    manageTagsModal.on('hide.bs.modal', function() {
      var tagsEl = $('#module-tags');

      // Load HTML
      $.ajax({
        url: tagsEl.attr('data-module-tags-url'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          var newOptions = $(data.html_module_header).find('option');
          $('#module-tags-selector').find('option').remove();
          $(newOptions).appendTo('#module-tags-selector').change();
        },
        error: function() {
          // TODO
        }
      });
    });

    // Remove modal content when modal window is closed.
    manageTagsModal.on('hidden.bs.modal', function() {
      manageTagsModalBody.html('');
    });
    // initialize my_module tab remote loading
    $('.edit-tags-link')
      .on('ajax:before', function() {
        manageTagsModal.modal('show');
      })
      .on('ajax:success', function(e, data) {
        $('#manage-module-tags-modal-module').text(data.my_module.name);
        initTagsModalBody(data);
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

    dropdownSelector.init(myModuleTagsSelector, {
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
        return `<span class="my-module-tags-color"></span>
                ${data.label + ' '}
                <span class="my-module-tags-create-new"> (${I18n.t('my_modules.details.create_new_tag')})</span>`;
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
      tagClass: 'my-module-white-tags',
      customDropdownIcon: () => {
        return '';
      },
      optionLabel: (data) => {
        return `<span class="global-avatar-container"><img src="${data.params.avatar_url}" alt="${data.label}"/></span>
                ${data.label}`;

      },
      onOpen: function() {
        $('.select-container .edit-button-container').removeClass('hidden');
      },
      onClose: function() {
        $('.select-container .edit-button-container').addClass('hidden');
      },
      onSelect: function() {
        var selectElement = $(myModuleUserSelector);
        var lastUser = selectElement.next().find('.ds-tags').last();
        var lastUserId = lastUser.find('.tag-label').data('ds-tag-id');
        var newUser;

        if (lastTagId > 0) {
          newUser = { my_module_user: { user_id: lastUserId } };
          $.post(selectElement.data('update-module-users-url'), newUser)
            .fail(function(response) {
              dropdownSelector.removeValue(myModuleUserSelector, lastUserId, '', true);
              if (response.status === 403) {
                HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
              }
            });
        } else {
          newUser = {
            tag: {
              name: lastUser.find('.tag-label').html(),
              project_id: selectElement.data('project-id'),
              color: null
            },
            my_module_id: selectElement.data('module-id'),
            simple_creation: true
          };
          $.post(selectElement.data('users-create-url'), newUser, function(result) {
            debugger
            dropdownSelector.removeValue(myModuleUserSelector, 0, '', true);
            dropdownSelector.addValue(myModuleUserSelector, {
              value: result.user.id,
              label: result.user.name,
              params: {
                avatar_url: result.user.avatar_url
              }
            }, true);
          }).fail(function() {
            dropdownSelector.removeValue(myModuleUserSelector, lastUserId, '', true);
          });
        }
      },
      onUnSelect: (id) => {
        $.destroy(`${$(myModuleUserSelector).data('data-update-module-users-url')}/${id}`)
          .success(function() {
            dropdownSelector.closeDropdown(myModuleUserSelector);
          })
          .fail(function(r) {
            if (r.status === 403) {
              HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
            }
          });
      }
    }).getContainer(myModuleUserSelector).addClass('my-module-users-container');
  }

  // function initAssignedUsersSelector() {
  //   var manageUsersModal = $('#manage-module-users-modal');
  //   var manageUsersModalBody = manageUsersModal.find('.modal-body');
  //
  //   // Initialize users editing modal remote loading
  //   function initUsersEditLink() {
  //     $('.task-details').on('ajax:success', '.manage-users-link', function(e, data) {
  //       manageUsersModal.modal('show');
  //       manageUsersModal.find('#manage-module-users-modal-module').text(data.my_module.name);
  //       initUsersModalBody(data);
  //     });
  //   }
  //
  //   // Initialize ajax listeners and elements style on modal body.
  //   // This function must be called when modal body is changed.
  //   function initUsersModalBody(data) {
  //     manageUsersModalBody.html(data.html);
  //     manageUsersModalBody.find('.selectpicker').selectpicker();
  //   }
  //
  //   // Initialize reloading manage user modal content after posting new user
  //   manageUsersModalBody.on('ajax:success', '.add-user-form', function(e, data) {
  //     initUsersModalBody(data);
  //   });
  //
  //   // Initialize remove user from my_module links
  //   manageUsersModalBody.on('ajax:success', '.remove-user-link', function(e, data) {
  //     initUsersModalBody(data);
  //   });
  //
  //   // Reload users HTML element when modal is closed
  //   manageUsersModal.on('hide.bs.modal', function() {
  //     var usersEl = $('.task-assigned-users');
  //     // Load HTML to refresh users
  //     $.ajax({
  //       url: usersEl.attr('data-module-users-url'),
  //       type: 'GET',
  //       dataType: 'json',
  //       success: function(data) {
  //         $('.task-assigned-users').replaceWith(data.html);
  //       },
  //       error: function() {
  //         // TODO
  //       }
  //     });
  //   });
  //
  //   // Remove users modal content when modal window is closed.
  //   manageUsersModal.on('hidden.bs.modal', function() {
  //     manageUsersModalBody.html('');
  //   });
  //
  //   initUsersEditLink();
  // }

  initTaskCollapseState();
  applyTaskStatusChangeCallBack();
  initTagsSelector();
  bindEditTagsAjax();
  initStartDatePicker();
  initDueDatePicker();
  initAssignedUsersSelector();
}());
