(function() {
  'use strict';

  function initNewUserAssignmentFormListener() {
    $(document).on('change', 'form#new-user-assignment-to-project-form', function() {
      let values = [];
      let count = 0;
      let submitBtn = $(this).find('input[type="submit"]');

      $(this).find('input:checked').each((_, el) => {
        let select = $(el).closest('.row').find('select');
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
  }

  $(document).one('turbolinks:load', initNewUserAssignmentFormListener);
}());
