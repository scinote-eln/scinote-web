/* global numberMinMaxValidator */

(function() {
  const field = $('#decimals.stock-column');

  const minValue = Number(field.data('min'));
  const maxValue = Number(field.data('max'));

  field.on('input', () => {
    field.val(numberMinMaxValidator(field.val(), minValue, maxValue));
  });
}());
