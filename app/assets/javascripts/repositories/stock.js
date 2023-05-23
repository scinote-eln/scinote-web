/* global dropdownSelector GLOBAL_CONSTANTS I18n SmartAnnotation formatDecimalValue Decimal */

var RepositoryStockValues = (function() {
  const UNIT_SELECTOR = '#repository-stock-value-units';

  function updateChangeAmount($element) {
    if (!$element.val()) {
      $('.stock-final-container .value').text('-');
      return;
    }
    if (!($element.val() >= 0)) return;

    let currentAmount = new Decimal($element.data('currentAmount') || 0);
    let inputAmount = new Decimal($element.val());
    let newAmount;

    switch ($element.data('operator')) {
      case 'set':
        newAmount = inputAmount;
        break;
      case 'add':
        newAmount = currentAmount.plus(inputAmount);
        break;
      case 'remove':
        newAmount = currentAmount.minus(inputAmount);
        break;
      default:
        newAmount = currentAmount;
        break;
    }
    $('#change_amount').val(inputAmount);

    $('#repository_stock_value_amount').val(newAmount);
    $('.stock-final-container').toggleClass('negative', newAmount < 0);
    $('.stock-final-container .value').text(
      formatDecimalValue(String(newAmount), $('#stock-input-amount').data('decimals'))
    );
  }

  function initManageAction() {
    let amountChanged = false;

    $('.repository-show').on('click', '.manage-repository-stock-value-link', function() {
      let colIndex = this.parentNode.cellIndex;
      let rowIndex = this.parentNode.parentNode.rowIndex;

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
            noEmptyOption: true,
            selectAppearance: 'simple',
            onChange: function() {
              let unit = '';
              if (dropdownSelector.getValues(UNIT_SELECTOR) > 0) {
                unit = dropdownSelector.getLabels(UNIT_SELECTOR);
              }
              $('.stock-final-container .units').text(unit);
              $('.repository-stock-reminder-value .units').text(
                I18n.t('repository_stock_values.manage_modal.units_remaining', {
                  unit: unit
                })
              );
            }
          });

          $manageModal.find(`
            .dropdown-selector-container .input-field,
            .dropdown-selector-container .search-field
          `).attr('tabindex', 2);

          $manageModal.find('form').on('ajax:success', function(_, data) {
            $manageModal.modal('hide');
            let $cell = $('.dataTable').find(
              `tr:nth-child(${rowIndex}) td:nth-child(${colIndex + 1})`
            );
            $cell.parent().data('manage-stock-url', data.manageStockUrl);
            $cell.html(
              $.fn.dataTable.render.RepositoryStockValue(data)
            );
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
                dropdownSelector.enableSelector(UNIT_SELECTOR);
                if (!amountChanged) { $stockInput.val($stockInput.data('currentAmount')); }
                break;
              case 'add':
                if (!amountChanged) { $stockInput.val(''); }
                dropdownSelector.disableSelector(UNIT_SELECTOR);
                break;
              case 'remove':
                if (!amountChanged) { $stockInput.val(''); }
                dropdownSelector.disableSelector(UNIT_SELECTOR);
                break;
              default:
                break;
            }

            updateChangeAmount($('#stock-input-amount'));
          });

          $('#stock-input-amount, #low_stock_threshold').on('input focus', function() {
            let decimals = $(this).data('decimals');
            this.value = formatDecimalValue(this.value, decimals);
          });

          SmartAnnotation.init($('#repository-stock-value-comment')[0], false);

          $('#repository-stock-value-comment').on('input', function() {
            $(this).closest('.sci-input-container').toggleClass(
              'error',
              this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
            );
            $('.update-repository-stock').toggleClass(
              'disabled',
              this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
            );
          });

          $('#reminder-selector-checkbox').on('change', function() {
            let valueContainer = $('.repository-stock-reminder-value');
            valueContainer.toggleClass('hidden', !this.checked);
            if (!this.checked) {
              $(this).data('reminder-value', valueContainer.find('input').val());
              valueContainer.find('input').val(null);
            } else {
              valueContainer.find('input').val($(this).data('reminder-value'));
              valueContainer.find('input').focus();
            }
          });

          $('.update-repository-stock').on('click', function() {
            let reminderError = $('#reminder-selector-checkbox')[0].checked
                                && $('.repository-stock-reminder-value').find('input').val() === '';
            $('.repository-stock-reminder-value').find('.sci-input-container').toggleClass('error', reminderError);
          });

          $('#stock-input-amount').on('input', function() {
            amountChanged = true;
            updateChangeAmount($(this));
          });

          $manageModal.on('ajax:beforeSend', 'form', function() {
            let status = true;
            if (!(dropdownSelector.getValues(UNIT_SELECTOR) > 0)) {
              dropdownSelector.showError(UNIT_SELECTOR, I18n.t('repository_stock_values.manage_modal.unit_error'));
              status = false;
            } else {
              dropdownSelector.hideError(UNIT_SELECTOR);
            }
            let stockInput = $('#stock-input-amount');
            if (stockInput.val().length && stockInput.val() >= 0) {
              stockInput.parent().removeClass('error');
            } else {
              stockInput.parent().addClass('error');
              if (stockInput.val().length === 0) {
                stockInput.parent()
                  .attr(
                    'data-error-text',
                    I18n.t('repository_stock_values.manage_modal.amount_error')
                  );
              } else {
                stockInput.parent()
                  .attr(
                    'data-error-text',
                    I18n.t('repository_stock_values.manage_modal.negative_error')
                  );
              }
              status = false;
            }

            let reminderInput = $('.repository-stock-reminder-value input');
            if ($('#reminder-selector-checkbox')[0].checked) {
              if (reminderInput.val().length && reminderInput.val() >= 0) {
                reminderInput.parent().removeClass('error');
              } else {
                reminderInput.parent().addClass('error');
                if (reminderInput.val().length === 0) {
                  reminderInput.parent()
                    .attr(
                      'data-error-text',
                      I18n.t('repository_stock_values.manage_modal.amount_error')
                    );
                } else {
                  reminderInput.parent()
                    .attr(
                      'data-error-text',
                      I18n.t('repository_stock_values.manage_modal.negative_error')
                    );
                }
                status = false;
              }
            }

            return status;
          });

          $manageModal.modal('show');
          amountChanged = false;
          $('#stock-input-amount').focus();
          $('#stock-input-amount')[0].selectionStart = $('#stock-input-amount')[0].value.length;
          $('#stock-input-amount')[0].selectionEnd = $('#stock-input-amount')[0].value.length;
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
