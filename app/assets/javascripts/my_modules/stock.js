/* global SmartAnnotation I18n MyModuleRepositories GLOBAL_CONSTANTS */
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
          $('#stock_consumption').focus();
          SmartAnnotation.init($(CONSUMPTION_MODAL + ' #comment')[0]);

          $('#stock_consumption').on('change', function() {
            let initialValue = parseFloat($(this).data('initial-value'));
            let initialStock = parseFloat($(this).data('initial-stock'));
            let finalValue = initialValue - ($(this).val() || 0) + initialStock;
            $('.stock-final-container .value').text(finalValue);
            $('.stock-final-container').toggleClass('error', finalValue <= 0);
            $('.update-consumption-button').attr('disabled', $(this).val() === '');
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
              this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
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
        $('#stock_consumption').focus();
      } else if (e.key === 'Enter') {
        $('.update-consumption-button').trigger('click', [true]);
      }
    })
    $(WARNING_MODAL).on('click', '.cancel-consumption', function(e) {
      $(WARNING_MODAL).modal('hide');
      $(CONSUMPTION_MODAL).modal('show');
      $('#stock_consumption').focus();
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
