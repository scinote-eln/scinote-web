(function() {
  'use strict';

  function initializeModal(modal) {
    var modalDialog = modal.find('.modal-dialog');
    var type = modal.attr('data-type');
    var stepForm = modal.find('[data-role=step-form]');
    var stepResults = modal.find('[data-role=step-results]');
    var inviteBtn = modal.find('[data-role=invite-btn]');
    var inviteWithRoleDiv =
      modal.find('[data-role=invite-with-role-div]');
    var inviteWithRoleBtn =
      modal.find('[data-role=invite-with-role-btn]');
    var orgSelectorCheckbox =
      modal.find('[data-role=org-selector-checkbox]');
    var orgSelectorDropdown =
      modal.find('[data-role=org-selector-dropdown]');
    var orgSelectorDropdown2 = $();
    var tagsInput = modal.find('[data-role=tagsinput]');

    modal
    .on('show.bs.modal', function() {
      // This cannot be scoped outside this function
      // because it is generated via JS
      orgSelectorDropdown2 =
        orgSelectorDropdown
        .next('.btn-group.bootstrap-select.form-control')
        .find('button.dropdown-toggle, li');

      // Show/hide correct step
      stepForm.show();
      stepResults.hide();

      // Show/hide buttons & other elements
      switch (type) {
        case 'invite_to_org_with_role':
        case 'invite':
        case 'invite_with_org_selector':
        case 'invite_with_org_selector_and_role':
          inviteBtn.show();
          inviteWithRoleDiv.hide();
          break;
        case 'invite_to_org':
          inviteBtn.hide();
          inviteWithRoleDiv.show();
          break;
        default:
          break;
      }

      // Checkbox toggle event
      if (
        type === 'invite_with_org_selector' ||
        type === 'invite_with_org_selector_and_role'
      ) {
        orgSelectorCheckbox.on('change', function() {
          if ($(this).is(':checked')) {
            orgSelectorDropdown.removeAttr('disabled');
            orgSelectorDropdown2.removeClass('disabled');
            if (type === 'invite_with_org_selector') {
              inviteBtn.hide();
              inviteWithRoleDiv.show();
            }
          } else {
            orgSelectorDropdown.attr('disabled', 'disabled');
            orgSelectorDropdown2.addClass('disabled');
            if (type === 'invite_with_org_selector') {
              inviteBtn.show();
              inviteWithRoleDiv.hide();
            }
          }
        });
      }

      // Toggle depending on input tags
      tagsInput
      .on('itemAdded', function(event) {
        inviteBtn.removeAttr('disabled');
        inviteWithRoleBtn.removeAttr('disabled');
      })
      .on('itemRemoved', function(event) {
        if ($(this).val() === null) {
          inviteBtn.attr('disabled', 'disabled');
          inviteWithRoleBtn.attr('disabled', 'disabled');
        }
      });

      // Click action
      $('[data-action=invite]').on('click', function() {
        animateSpinner(modalDialog);

        var data = {
          emails: tagsInput.val()
        };
        switch (type) {
          case 'invite_to_org':
            data.organizationId = modal.attr('data-organization-id');
            data.role = $(this).attr('data-organization-role');
            break;
          case 'invite_to_org_with_role':
            data.organizationId = modal.attr('data-organization-id');
            data.role = modal.attr('data-organization-role');
            break;
          case 'invite':
            break;
          case 'invite_with_org_selector':
            if (orgSelectorCheckbox.is(':checked')) {
              data.organizationId = orgSelectorDropdown.val();
              data.role = $(this).attr('data-organization-role');
            }
            break;
          case 'invite_with_org_selector_and_role':
            if (orgSelectorCheckbox.is(':checked')) {
              data.organizationId = orgSelectorDropdown.val();
              data.role = modal.attr('data-organization-role');
            }
            break;
          default:
            break;
        }

        $.ajax({
          method: 'POST',
          url: modal.attr('data-url'),
          dataType: 'json',
          data: data,
          success: function(data) {
          }
        });
      });
    })
    .on('shown.bs.modal', function() {
      tagsInput.tagsinput('focus');
    })
    .on('hide.bs.modal', function() {
      // 'Reset' modal state
      tagsInput.tagsinput('removeAll');
      orgSelectorCheckbox.prop('checked', false);
      inviteBtn.attr('disabled', 'disabled');
      inviteWithRoleBtn.attr('disabled', 'disabled');
      orgSelectorDropdown2.addClass('disabled');
      animateSpinner(modalDialog, false);

      // Unbind event listeners
      orgSelectorCheckbox.off('change');
      tagsInput.off('itemAdded itemRemoved');
    });
  }

  function initializeModalsToggle() {
    $("[data-trigger='invite-users']").on('click', function() {
      var id = $(this).attr('data-modal-id');
      $('[data-role=invite-users-modal][data-id=' + id + ']')
      .modal('show');
    });
  }

  $(document).ready(function() {
    $('[data-role=invite-users-modal]').each(function() {
      initializeModal($(this));
    });
    initializeModalsToggle();
  });
})();
