/* global SmartAnnotation I18n */
var MyModuleStockConsumption = (function() {
  const CONSUMPTION_MODAL = '#consumeRepositoryStockValueModal';
  const WARNING_MODAL = '#consumeRepositoryStockValueModalWarning';

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
          SmartAnnotation.init($(CONSUMPTION_MODAL + ' #comment')[0]);

          $('#stock_consumption').on('change', function() {
            let initialValue = parseFloat($(this).data('initial-value'));
            let initialStock = parseFloat($(this).data('initial-stock'));
            let finalValue = initialValue - ($(this).val() || 0) + initialStock;
            $('.stock-final-container .value').text(finalValue);
            $('.stock-final-container').toggleClass('error', finalValue <= 0);
            $('.update-consumption-button').attr('disabled', $(this).val() === '');
          });

          $('.update-consumption-button').on('click', function(event) {
            event.preventDefault();

            if (parseFloat($('.stock-final-container .value').text()) < 0) {
              $manageModal.modal('hide');
              $(WARNING_MODAL).modal('show');
              let units = $(CONSUMPTION_MODAL).find('.consumption-container .units').text();
              let value = $('#stock_consumption').val();
              $(WARNING_MODAL).find('.modal-body p').text(
                I18n.t('my_modules.repository.stock_warning_modal.description', { value: `${value} ${units}` })
              );
            } else {
              $(CONSUMPTION_MODAL + ' form')[0].submit();
            }
          });
        }
      });
    });
  }

  function initWarningModal() {
    $(WARNING_MODAL).on('click', '.cancel-consumption', function() {
      $(WARNING_MODAL).modal('hide');
      $(CONSUMPTION_MODAL).modal('show');
    }).on('click', '.confirm-consumption-button', function() {
      $(CONSUMPTION_MODAL + ' form')[0].submit();
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
