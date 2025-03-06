/* global dropdownSelector initBSTooltips I18n */

(function() {
  function initNewMyModuleModal() {
    let experimentWrapper = '.experiment-new-my_module';
    let newMyModuleModal = '#new-my-module-modal';
    let myModuleUserSelector = '#my_module_user_ids';
    var myModuleTagsSelector = '#module-tags-selector';

    $('#experiment-canvas').on('submit', '#new-my-module-modal form', (event) => {
      event.preventDefault();

      $.post({
        url: $('#new-my-module-modal form').attr('action'),
        data: {
          my_module: {
            name: $('#new-my-module-modal input[name="my_module[name]"]').val(),
            view_mode: $('#new-my-module-modal input[name="my_module[view_mode]"]').val(),
            due_date: $('#new-my-module-modal input[name="my_module[due_date]"]').val(),
            tag_ids: dropdownSelector.getValues(myModuleTagsSelector),
            user_ids: dropdownSelector.getValues(myModuleUserSelector)
          }
        }
      });
    });

    $('#experiment-canvas').on('shown.bs.modal', () => {
      // disable the submit button by default
      $('#new-modal-submit-btn').prop('disabled', true);

      // listen for input event on the my_module_name input field
      $(`${newMyModuleModal} #my_module_name`).on('input', function () {
        if ($(this).val().trim().length > 1) {
          // enable the submit button if the input field is populated
          $('#new-modal-submit-btn').prop('disabled', false);
        } else {
          // otherwise, disable it
          $('#new-modal-submit-btn').prop('disabled', true);
        }
      });
    });

    // Modal's submit handler function
    $(experimentWrapper)
      .on('ajax:success', newMyModuleModal, function() {
        $(this).find('sci-input-container').removeClass('error');
        $(newMyModuleModal).modal('hide');
      })
      .on('ajax:error', newMyModuleModal, function(ev, data) {
        let errors = data.responseJSON;
        $(this).find('sci-input-container').removeClass('error');
        if (errors.name) {
          $(this).find('#my_module_name')
            .parent()
            .addClass('error')
            .attr('data-error-text', errors.name.join(', '));
        }
      })
      .on('submit', newMyModuleModal, function() {
        // To submit correct assigned user ids to new modal
        // Clear default selected user in dropdown
        $(`${myModuleUserSelector} option[value=${$('#new-my-module-modal').data('user-id')}]`)
          .prop('selected', false);
        $.map(dropdownSelector.getValues(myModuleUserSelector), function(val) {
          $(`${myModuleUserSelector} option[value=${val}]`).prop('selected', true);
        });
      })
      .on('ajax:success', '.new-my-module-button', function(ev, result) {
        // Add and show modal
        $(experimentWrapper).append($.parseHTML(result.html));
        $(newMyModuleModal).modal('show');
        window.initDateTimePickerComponent(`#date-time-picker-my-module`);
        $(newMyModuleModal).find("input[type='text']").focus();

        // Remove modal when it gets closed
        $(newMyModuleModal).on('hidden.bs.modal', function() {
          $(newMyModuleModal).remove();
        });

        // initiaize user assing dropdown menu
        dropdownSelector.init(myModuleUserSelector, {
          closeOnSelect: true,
          labelHTML: true,
          tagLabel: (data) => {
            return `<div class="flex items-center gap-2">
                      <img class="img-responsive block-inline" src="${data.params.avatar_url}" alt="${data.label}"/>
                      <span class="user-full-name block-inline">${data.label}</span>
                    </div>`;
          },
          optionLabel: (data) => {
            if (data.params.avatar_url) {
              return `<div class="flex items-center gap-2">
                        <span class="global-avatar-container">
                        <img src="${data.params.avatar_url}" alt="${data.label}"/></span>
                        <span style="margin-left: 10px">${data.label}</span>
                      </div>`;
            }

            return data.label;
          }
        });

        dropdownSelector.selectValues(myModuleUserSelector, $('#new-my-module-modal').data('user-id'));

        dropdownSelector.init($(myModuleTagsSelector), {
          closeOnSelect: true,
          tagClass: 'my-module-white-tags sci-tag',
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
          ajaxParams: function(params) {
            let newParams = params;
            newParams.selected_tags = JSON.stringify(dropdownSelector.getValues(myModuleTagsSelector));
            return newParams;
          },
          onSelect: function() {
            var selectElement = $(myModuleTagsSelector);
            var lastTag = selectElement.next().find('.ds-tags').last();
            var lastTagId = lastTag.find('.tag-label').data('ds-tag-id');

            if (lastTagId > 0) {
              $('#my_module_tag_ids').val(JSON.stringify(dropdownSelector.getValues(myModuleTagsSelector)));
            } else {
              let newTag = {
                tag: {
                  name: lastTag.find('.tag-label').html(),
                  project_id: selectElement.data('project-id'),
                  color: null
                },
                simple_creation: true
              };
              $.post(selectElement.data('tags-create-url'), newTag, function(res) {
                dropdownSelector.removeValue(myModuleTagsSelector, 0, '', true);
                dropdownSelector.addValue(myModuleTagsSelector, {
                  value: res.tag.id,
                  label: res.tag.name,
                  params: {
                    color: res.tag.color
                  }
                }, true);
                $('#my_module_tag_ids').val(JSON.stringify(dropdownSelector.getValues(myModuleTagsSelector)));
              }).fail(function() {
                dropdownSelector.removeValue(myModuleTagsSelector, lastTagId, '', true);
              });
            }
          }
        });
      });
    initBSTooltips();
  }

  function initAccessModal() {
    $('#experiment-canvas').on('click', '.openAccessModal', (e) => {
      e.preventDefault();
      const { target } = e;
      $.get(target.dataset.url, (data) => {
        const object = {
          ...data.data.attributes,
          id: data.data.id,
          type: data.data.type
        };
        const { rolesUrl } = target.dataset;
        const params = {
          object: object,
          roles_path: rolesUrl
        };
        const modal = $('#accessModalComponent').data('accessModal');
        modal.params = params;
        modal.open();
      });
    });
  }

  initNewMyModuleModal();
  initAccessModal();
}());
