/* global SmartAnnotation I18n MyModuleRepositories GLOBAL_CONSTANTS formatDecimalValue Decimal */
var MyModuleStockConsumption = (function() {
  const CONSUMPTION_MODAL = '#consumeRepositoryStockValueModal';
  const WARNING_MODAL = '#consumeRepositoryStockValueModalWarning';

  function focusStockConsumption() {
    // focus and move cursor to end of text
    var $stockConsumption = $('#stock_consumption');
    $stockConsumption[0].setSelectionRange(
      $stockConsumption.val().length,
      $stockConsumption.val().length
    );
    $stockConsumption.focus();
  }

  function initManageAction() {
    $('.task-section').on('click', '.manage-repository-consumed-stock-value-link', function(e) {
      e.preventDefault();
      $.ajax({
        url: $(this).attr('href'),
        type: 'GET',
        dataType: 'json',
        success: (result) => {
          var $manageModal = $(CONSUMPTION_MODAL);
          $manageModal.find('.modal-content').html(result.html);
          $manageModal.modal('show');
          focusStockConsumption();
          SmartAnnotation.init($(CONSUMPTION_MODAL + ' #comment')[0], false);

          $('#stock_consumption').on('input', function() {
            let initialValue = new Decimal($(this).data('initial-value') || 0);
            let initialStock = new Decimal($(this).data('initial-stock'));
            let decimals = $(this).data('decimals');
            this.value = formatDecimalValue(String(this.value), decimals);
            let finalValue = initialValue.minus(new Decimal($(this).val() || 0)).plus(initialStock);
            $('.stock-final-container .value')
              .text(formatDecimalValue(String(finalValue), $('#stock_consumption').data('decimals')));
            $('.stock-final-container').toggleClass('negative', finalValue <= 0);
            $(this).closest('.sci-input-container').toggleClass('error', !($(this).val().length && this.value >= 0));
            if ($(this).val().length === 0) {
              $(this).closest('.sci-input-container')
                .attr(
                  'data-error-text',
                  I18n.t('repository_stock_values.manage_modal.amount_error')
                );
            } else if (this.value <= 0) {
              $(this).closest('.sci-input-container')
                .attr(
                  'data-error-text',
                  I18n.t('repository_stock_values.manage_modal.negative_error')
                );
            }
            $('.update-consumption-button').attr('disabled', !($(this).val().length && this.value >= 0));
          });

          $(CONSUMPTION_MODAL + ' form').on('ajax:success', function() {
            MyModuleRepositories.reloadSimpletable();
            MyModuleRepositories.reloadFullViewTable();
            $manageModal.modal('hide');
            $(WARNING_MODAL).modal('hide');
          });

          $(CONSUMPTION_MODAL + ' #comment').on('keyup change', function() {
            $(this).closest('.sci-input-container').toggleClass(
              'error',
              this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
            );
            $('.update-consumption-button').attr(
              'disabled',
              this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH || $('#stock_consumption').val() === ''
            );
          });


          $('.update-consumption-button').on('click', function(event, skipValidation) {
            if (parseFloat($('.stock-final-container .value').text()) < 0 && !skipValidation) {
              event.preventDefault();
              $manageModal.modal('hide');
              $(WARNING_MODAL).modal('show');
              let units = $(CONSUMPTION_MODAL).find('.consumption-container .units').text();
              let value = $('#stock_consumption').val();
              $(WARNING_MODAL).find('.modal-body p').html(
                I18n.t('my_modules.repository.stock_warning_modal.description_html', { value: `${value} ${units}` })
              );
            }
          });
        }
      });
    });
  }

  function initWarningModal() {
    $(WARNING_MODAL).on('keydown', function(e) {
      if (e.key === 'Escape') {
        $(WARNING_MODAL).modal('hide');
        $(CONSUMPTION_MODAL).modal('show');
        focusStockConsumption();
      } else if (e.key === 'Enter') {
        $('.update-consumption-button').trigger('click', [true]);
      }
    });
    $(WARNING_MODAL).on('click', '.cancel-consumption', function(e) {
      $(WARNING_MODAL).modal('hide');
      $(CONSUMPTION_MODAL).modal('show');
      focusStockConsumption();
    }).on('click', '.confirm-consumption-button', function() {
      $('.update-consumption-button').trigger('click', [true]);
    });
  }

  return {
    init: () => {
      initManageAction();
      initWarningModal();
    }
  };
}());

MyModuleStockConsumption.init();
