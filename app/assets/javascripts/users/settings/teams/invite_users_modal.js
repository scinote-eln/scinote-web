(function() {
  'use strict';

  function reloadRecaptchaIfExists() {
    if (typeof grecaptcha !== 'undefined') {
      grecaptcha.reset();
    }
  }

  window.recaptchaCallback = function recaptchaCallback(response) {
    $('#recaptcha-invite-modal').val(response);
  };

  function initializeModal(modal) {
    var modalDialog = modal.find('.modal-dialog');
    var type = modal.attr('data-type');
    var stepForm = modal.find('[data-role=step-form]');
    var stepResults = modal.find('[data-role=step-results]');
    var stepResultsDiv = modal.find('[data-role=step-results][data-clear]');
    var inviteBtn = modal.find('[data-role=invite-btn]');
    var inviteWithRoleDiv = modal.find('[data-role=invite-with-role-div]');
    var inviteWithRoleBtn = modal.find('[data-role=invite-with-role-btn]');
    var teamSelectorCheckbox = modal.find('[data-role=team-selector-checkbox]');
    var teamSelectorDropdown = modal.find('[data-role=team-selector-dropdown]');
    var teamSelectorDropdown2 = $();
    var tagsInput = modal.find('[data-role=tags-input]');
    var recaptchaErrorMsgDiv = modal.find('#recaptcha-error-msg');
    var recaptchaErrorText = modal.find('#recaptcha-error-msg>span');

    // Set max tags
    tagsInput.tagsinput({
      maxTags: modal.data('max-tags')
    });

    modal.off('show.bs.modal').on('show.bs.modal', function() {
      // This cannot be scoped outside this function
      // because it is generated via JS
      teamSelectorDropdown2 = teamSelectorDropdown.parent()
        .find('button.dropdown-toggle, li');

      // Show/hide correct step
      stepForm.show();
      stepResults.hide();

      // Show/hide buttons & other elements
      switch (type) {
        case 'invite_to_team_with_role':
        case 'invite':
        case 'invite_with_team_selector':
        case 'invite_with_team_selector_and_role':
          inviteBtn.show();
          inviteWithRoleDiv.hide();
          break;
        case 'invite_to_team':
          inviteBtn.hide();
          inviteWithRoleDiv.show();
          break;
        default:
          break;
      }

      // Checkbox toggle event
      if (
        type === 'invite_with_team_selector' ||
        type === 'invite_with_team_selector_and_role'
      ) {
        teamSelectorCheckbox.on('change', function() {
          if ($(this).is(':checked')) {
            teamSelectorDropdown.removeAttr('disabled');
            teamSelectorDropdown2.removeClass('disabled');
            if (type === 'invite_with_team_selector') {
              inviteBtn.hide();
              inviteWithRoleDiv.show();
            }
          } else {
            teamSelectorDropdown.attr('disabled', 'disabled');
            teamSelectorDropdown2.addClass('disabled');
            if (type === 'invite_with_team_selector') {
              inviteBtn.show();
              inviteWithRoleDiv.hide();
            }
          }
        });
      }

      // Toggle depending on input tags
      tagsInput.on('itemAdded', function() {
        inviteBtn.removeAttr('disabled');
        inviteWithRoleBtn.removeAttr('disabled');
      }).on('itemRemoved', function() {
        if ($(this).val() === null) {
          inviteBtn.attr('disabled', 'disabled');
          inviteWithRoleBtn.attr('disabled', 'disabled');
        }
      });

      // Click action
      modal.find('[data-action=invite]').off('click').on('click', function() {
        var data = {
          emails: tagsInput.val(),
          'g-recaptcha-response': $('#recaptcha-invite-modal').val()
        };

        animateSpinner(modalDialog);

        switch (type) {
          case 'invite_to_team':
            data.teamId = modal.attr('data-team-id');
            data.role = $(this).attr('data-team-role');
            break;
          case 'invite_to_team_with_role':
            data.teamId = modal.attr('data-team-id');
            data.role = modal.attr('data-team-role');
            break;
          case 'invite':
            break;
          case 'invite_with_team_selector':
            if (teamSelectorCheckbox.is(':checked')) {
              data.teamId = teamSelectorDropdown.val();
              data.role = $(this).attr('data-team-role');
            }
            break;
          case 'invite_with_team_selector_and_role':
            if (teamSelectorCheckbox.is(':checked')) {
              data.teamId = teamSelectorDropdown.val();
              data.role = modal.attr('data-team-role');
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
            animateSpinner(modalDialog, false);
            stepForm.hide();
            stepResultsDiv.html(data.html);
            stepResults.show();
            // Add 'data-invited="true"' status to modal element
            modal.attr('data-invited', 'true');
          },
          error: function(jqXHR) {
            // ReCaptcha fails
            if (jqXHR.status === 422) {
              recaptchaErrorMsgDiv.removeClass('hidden');
              recaptchaErrorText.text(jqXHR.responseJSON.recaptcha_error);
            } else {
              modal.modal('hide');
              alert('Error inviting users.');
            }
            reloadRecaptchaIfExists();
            animateSpinner(modalDialog, false);
          }
        });
      });
    }).on('shown.bs.modal', function() {
      var script = document.createElement('script');
      tagsInput.tagsinput('focus');
      recaptchaErrorMsgDiv.addClass('hidden');
      script.type = 'text/javascript';
      script.src = 'https://www.google.com/recaptcha/api.js?hl=en';
      $(script).insertAfter('#recaptcha-service');
      // Remove 'data-invited="true"' status
      modal.removeAttr('data-invited');
    }).on('hide.bs.modal', function() {
      // 'Reset' modal state
      tagsInput.tagsinput('removeAll');
      teamSelectorCheckbox.prop('checked', false);
      inviteBtn.attr('disabled', 'disabled');
      inviteWithRoleBtn.attr('disabled', 'disabled');
      teamSelectorDropdown2.addClass('disabled');
      animateSpinner(modalDialog, false);
      recaptchaErrorMsgDiv.addClass('hidden');
      $('#recaptcha-service').next().remove();

      // Unbind event listeners
      teamSelectorCheckbox.off('change');
      tagsInput.off('itemAdded itemRemoved');
      modal.find('[data-action=invite]').off('click');

      // Hide contents of the results <div>
      stepResultsDiv.html('');
      stepResults.hide();
      stepForm.show();
      reloadRecaptchaIfExists();
      $('#recaptcha-invite-modal').val('');
    });
  }

  function initializeModalsToggle() {
    $(document).off('click', "[data-trigger='invite-users']")
      .on('click', "[data-trigger='invite-users']", function(event) {
        var id = $(this).attr('data-modal-id');
        event.preventDefault();
        event.stopPropagation();
        $('[data-role=invite-users-modal][data-id=' + id + ']')
          .modal('show');
      });
  }

  $(document).on('turbolinks:load', function() {
    $('[data-role=invite-users-modal]').each(function() {
      initializeModal($(this));
    });

    initializeModalsToggle();
  });
}());
