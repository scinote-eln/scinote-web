var MyModuleStockConsumption = (function() {
  function initManageAction() {
    $('.task-section').on('click', '.manage-repository-consumed-stock-value-link', function(e) {
      e.preventDefault();
      $.ajax({
        url: $(this).attr('href'),
        type: 'GET',
        dataType: 'json',
        success: (result) => {
          var $manageModal = $('#consumeRepositoryStockValueModal');
          $manageModal.find('.modal-content').html(result.html);
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

MyModuleStockConsumption.init();
