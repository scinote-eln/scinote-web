/* global dropdownSelector GLOBAL_CONSTANTS */

var RepositoryStockValues = (function() {
  const UNIT_SELECTOR = '#repository-stock-value-units';

  function initManageAction() {
    $('.repository-show').on('click', '.manage-repository-stock-value-link', function() {
      $.ajax({
        url: $(this).closest('tr').data('manage-stock-url'),
        type: 'GET',
        dataType: 'json',
        success: (result) => {
          var $manageModal = $('#manage-repository-stock-value-modal');
          $manageModal.find('.modal-content').html(result.html);

          dropdownSelector.init(UNIT_SELECTOR, {
            singleSelect: true,
            closeOnSelect: true,
            selectAppearance: 'simple',
            onChange: function() {
              $('.stock-final-container .units').text(dropdownSelector.getLabels(UNIT_SELECTOR));
            }
          });

          $manageModal.find('form').on('ajax:success', function() {
            var dataTable = $('.dataTable').DataTable();
            $manageModal.modal('hide');
            dataTable.ajax.reload();
          });

          $('.stock-operator-option').click(function() {
            var $stockInput = $('#stock-input-amount');
            $('.stock-operator-option').removeClass('btn-primary').addClass('btn-secondary');
            $(this).removeClass('btn-secondary').addClass('btn-primary');
            $stockInput.data('operator', $(this).data('operator'));

            dropdownSelector.selectValues(UNIT_SELECTOR, $('#initial_units').val());
            $('#operator').val($(this).data('operator'));

            switch ($(this).data('operator')) {
              case 'set':
                $stockInput.val($stockInput.data('currentAmount'));
                dropdownSelector.enableSelector(UNIT_SELECTOR);
                break;
              case 'add':
                $stockInput.val('');
                dropdownSelector.disableSelector(UNIT_SELECTOR);
                break;
              case 'remove':
                $stockInput.val('');
                dropdownSelector.disableSelector(UNIT_SELECTOR);
                break;
              default:
                break;
            }
          });

          $('#repository-stock-value-comment').on('keyup change', function() {
            $(this).closest('.sci-input-container').toggleClass(
              'error',
              this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
            );
            $('.update-repository-stock').toggleClass(
              'disabled',
              this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
            );
          });

          $('#stock-input-amount').on('input', function() {
            var currentAmount = parseFloat($(this).data('currentAmount'));
            var inputAmount = parseFloat($(this).val());
            var newAmount;

            if (!inputAmount) return;

            switch ($(this).data('operator')) {
              case 'set':
                newAmount = inputAmount;
                break;
              case 'add':
                newAmount = currentAmount + inputAmount;
                break;
              case 'remove':
                newAmount = currentAmount - inputAmount;
                break;
              default:
                newAmount = currentAmount;
                break;
            }
            $('#change_amount').val(inputAmount);

            $('#repository_stock_value_amount').val(newAmount);
            $('.stock-final-container .value').text(newAmount);
          });

          $manageModal.modal('show');
        }
      });
    });
  }

  return {
    init: () => {
      initManageAction();
    }
  };
}());

RepositoryStockValues.init();
