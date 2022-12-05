/* global dropdownSelector */

(function() {
  function initNewMyModuleModal() {
    let experimentWrapper = '.experiment-new-my_module';
    let newMyModuleModal = '#new-my-module-modal';
    let myModuleUserSelector = '#my_module_user_ids';

    // Modal's submit handler function
    $(experimentWrapper)
      .on('ajax:success', newMyModuleModal, function() {
        $(newMyModuleModal).modal('hide');
      })
      .on('ajax:error', newMyModuleModal, function(ev, data) {
        $(this).renderFormErrors('my_module', data.responseJSON);
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
        $(newMyModuleModal).find("input[type='text']").focus();

        // Remove modal when it gets closed
        $(newMyModuleModal).on('hidden.bs.modal', function() {
          $(newMyModuleModal).remove();
        });

        // initiaize user assing dropdown menu
        dropdownSelector.init(myModuleUserSelector, {
          closeOnSelect: true,
          labelHTML: true,
          tagClass: 'my-module-user-tags',
          tagLabel: (data) => {
            return `<img class="img-responsive block-inline" src="${data.params.avatar_url}" alt="${data.label}"/>
                    <span style="user-full-name block-inline">${data.label}</span>`;
          },
          optionLabel: (data) => {
            if (data.params.avatar_url) {
              return `<span class="global-avatar-container" style="margin-top: 10px">
                      <img src="${data.params.avatar_url}" alt="${data.label}"/></span>
                      <span style="margin-left: 10px">${data.label}</span>`;
            }

            return data.label;
          }
        });

        dropdownSelector.selectValues(myModuleUserSelector, $('#new-my-module-modal').data('user-id'));
      });
  }

  initNewMyModuleModal();
}());
