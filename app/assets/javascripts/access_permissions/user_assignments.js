/* global HelperModule I18n */

(function() {
  'use strict';

  function initNewUserAssignmentFormListener() {
    $(document).on('change', 'form#new-user-assignment-form', function() {
      let values = [];
      let count = 0;
      let submitBtn = $(this).find('input[type="submit"]');

      $(this).find('input:checked').each((_, el) => {
        let select = $(el).closest('.new-member-item').find('select');
        let selectValue = parseInt(select.val(), 10);
        values.push(selectValue);
        count += 1;

        if (isNaN(selectValue)) {
          select.closest('.form-group ')
            .addClass('has-error');
        } else {
          select.closest('.form-group ')
            .removeClass('has-error');
        }
      });

      if (values.includes(NaN) || values.length === 0) {
        submitBtn.attr('disabled', 'disabled');
      } else {
        submitBtn.attr('disabled', false);
      }

      switch (count) {
        case 0:
          submitBtn.val(submitBtn.data('label-default'));
          break;
        case 1:
          submitBtn.val(submitBtn.data('label-singular'));
          break;
        default:
          submitBtn.val(submitBtn.data('label-plural').replace('{num}', count));
      }
    });

    $(document).on('ajax:success', 'form#new-user-assignment-form', function(_e, data) {
      $('#user_assignments_modal').replaceWith($(data.html).find('#user_assignments_modal'));
      HelperModule.flashAlertMsg(data.flash, 'success');

      if (window.actionToolbarComponent?.reloadCallback) {
        window.actionToolbarComponent.reloadCallback();
      }
    });

    $(document).on('ajax:error', 'form#new-user-assignment-form', function(_e, data) {
      HelperModule.flashAlertMsg(data.responseJSON.flash
        ? data.responseJSON.flash : I18n.t('errors.general'), 'danger');
    });

    $(document).on('ajax:error', 'form.member-item', function(_e, data) {
      HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
    });

    $(document).on('ajax:success', 'form.member-item', function(_e, data) {
      if (data.flash) {
        HelperModule.flashAlertMsg(data.flash, 'success');
      }

      if (window.actionToolbarComponent?.reloadCallback) {
        window.actionToolbarComponent.reloadCallback();
      }
    });

    $(document).on('click', '.user-assignment-dropdown .user-role-selector', function() {
      let roleId = $(this).data('role-id');
      $(this).closest('.dropdown').find('#user_assignment_user_role_id, .default-public-user-role-id').val(roleId);
      $(this).closest('form').trigger('submit');
    });
  }

  $(document).one('turbolinks:load', initNewUserAssignmentFormListener);
}());
