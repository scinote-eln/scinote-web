/* global animateSpinner GLOBAL_CONSTANTS */

(function() {
  $('.task-sharing-and-flows').on('click', '#viewTaskFlow', function() {
    $('#statusFlowModal').off('shown.bs.modal').on('shown.bs.modal', function() {
      var $modalBody = $(this).find('.modal-body');
      animateSpinner($modalBody);
      $.get($(this).data('status-flow-url'), function(result) {
        animateSpinner($modalBody, false);
        $modalBody.html(result.html);
      });
    });

    $('#statusFlowModal').modal('show');
  });

  function checkStatusState() {
    $.getJSON($('.status-flow-dropdown').data('status-check-url'), (statusData) => {
      if (statusData.status_changing) {
        setTimeout(() => { checkStatusState(); }, GLOBAL_CONSTANTS.FAST_STATUS_POLLING_INTERVAL);
      } else {
        $('.task-sharing-and-flows .status-flow-container').replaceWith(statusData.html);
      }
    });
  }

  function applyTaskStatusChangeCallBack() {
    if ($('.status-flow-dropdown').data('status-changing')) {
      setTimeout(() => { checkStatusState(); }, GLOBAL_CONSTANTS.FAST_STATUS_POLLING_INTERVAL);
    }
    $('.task-sharing-and-flows').on('click', '#dropdownTaskFlowList > li[data-state-id]', function() {
      var list = $('#dropdownTaskFlowList');
      var item = $(this);
      animateSpinner();
      $.ajax({
        url: list.data('link-url'),
        beforeSend: function(e, ajaxSettings) {
          if (item.data('beforeSend') instanceof Function) {
            return item.data('beforeSend')(item, ajaxSettings)
          }
          return true
        },
        type: 'PATCH',
        data: { my_module: { status_id: item.data('state-id') } },
        success: function(result) {
          animateSpinner(null, false);
          $('.task-sharing-and-flows .status-flow-container').replaceWith(result.html);
          if (result.status_changing) {
            setTimeout(() => { checkStatusState(); }, GLOBAL_CONSTANTS.FAST_STATUS_POLLING_INTERVAL);
          }
        },
        error: function(e) {
          animateSpinner(null, false);
          if (e.status === 403) {
            HelperModule.flashAlertMsg(I18n.t('my_module_statuses.update_status.error.no_permission'), 'danger');
          } else if (e.status === 422) {
            HelperModule.flashAlertMsg(e.responseJSON.errors, 'danger');
          } else {
            HelperModule.flashAlertMsg('error', 'danger');
          }
        }
      });
    });
  }

  applyTaskStatusChangeCallBack();
}());
