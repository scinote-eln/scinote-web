/* global animateSpinner $ ActionCableConsumer HelperModule I18n */

(function() {
  var $statusContainer = $('#status-container');
  var renderedWhileChanging = !!$statusContainer.find('.status-flow-dropdown').data('status-changing');
  var displayedState = {
    my_module_status_id: $statusContainer.data('current-status-id'),
    status_changing: renderedWhileChanging,
    transition_failed: $statusContainer.find('.status-transition-error').length > 0
  };
  var reloadPending = false;

  function initStatusFlowModal() {
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
  }

  function applyTaskStatusChangeCallBack() {
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
          location.reload();
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

  // The status toggle opens with Alt+Shift+S (data-shortcut). The options use display: contents and
  // can't take focus, so focus stays on the toggle: Tab/Arrows move the keyboard-active highlight,
  // Enter/Space applies it through the click handler above, Esc is handled by Bootstrap.
  function initStatusKeyboard() {
    const $flows = $('.task-sharing-and-flows');
    const options = '#dropdownTaskFlowList > li[data-state-id]:not(.disabled)';

    function highlight($option) {
      $flows.find('.keyboard-active').removeClass('keyboard-active');
      if ($option) $option.addClass('keyboard-active');
    }

    // Opened without a pointer (shortcut, Enter, Space): start on "next status"
    $flows.on('click', '.status-flow-dropdown [data-toggle="dropdown"]', (e) => {
      const $options = $flows.find(options);
      const $next = $options.filter('#nextStatusSelector');
      if (e.detail || $(e.currentTarget).hasClass('disabled')) return;

      highlight($next.length ? $next : $options.first());
    });

    $flows.on('keydown', '.status-flow-dropdown.open [data-toggle="dropdown"]', (e) => {
      const $options = $flows.find(options);
      const index = $options.index($options.filter('.keyboard-active'));
      const step = e.key === 'ArrowUp' || (e.key === 'Tab' && e.shiftKey) ? -1 : 1;

      if (e.altKey || e.ctrlKey || e.metaKey || !$options.length) return;

      if (['Tab', 'ArrowDown', 'ArrowUp'].includes(e.key)) {
        e.preventDefault();
        // .eq(-1) is the last option
        highlight($options.eq(index === -1 && step < 0 ? -1 : (index + step) % $options.length));
      } else if ((e.key === 'Enter' || e.key === ' ') && index !== -1) {
        e.preventDefault();
        $options.eq(index).trigger('click');
      }
    });

    // Only one option looks selected: the pointer takes over, and closing clears it
    $flows.on('mouseenter', '#dropdownTaskFlowList > li', () => highlight());
    $flows.on('hidden.bs.dropdown', '.status-flow-dropdown', () => highlight());
  }

  function reloadWhenTransitionEnds() {
    if (reloadPending) return;

    reloadPending = true;
    $.getJSON($statusContainer.find('.status-flow-dropdown').data('status-check-url'), (statusData) => {
      if (statusData.status_changing) {
        reloadPending = false;
        return;
      }
      location.reload();
    }).fail(() => { reloadPending = false; });
  }

  function refreshStatus(state) {
    $.get($statusContainer.data('status-partial-url'), (partialData) => {
      var statusIdChanged = state.my_module_status_id !== displayedState.my_module_status_id;

      displayedState = state;
      $statusContainer.data('current-status-id', state.my_module_status_id);
      $statusContainer.html(partialData.html);
      if (window.SciNoteShortcuts) window.SciNoteShortcuts.decorate($statusContainer[0]);
      if (statusIdChanged) $statusContainer.trigger('statusChanged');
    });
  }

  function handleStatusState(state) {
    if (!state || !$statusContainer.length) return;

    if (renderedWhileChanging) {
      if (!state.status_changing) reloadWhenTransitionEnds();
      return;
    }

    if (state.my_module_status_id === displayedState.my_module_status_id
        && state.status_changing === displayedState.status_changing
        && state.transition_failed === displayedState.transition_failed) return;

    refreshStatus(state);
  }

  function unsubscribeFromStatusChannel() {
    if (!window.myModuleStatusSubscription) return;

    ActionCableConsumer.subscriptions.remove(window.myModuleStatusSubscription);
    window.myModuleStatusSubscription = null;
  }

  function subscribeToStatusChannel() {
    if (!$statusContainer.length || !window.ActionCableConsumer) return;

    var myModuleId = $statusContainer.data('my-module-id');

    // Turbolinks re-runs this script on every visit without rebooting the JS
    // runtime, so an earlier subscription would otherwise stay alive and act on
    // a page it no longer belongs to.
    unsubscribeFromStatusChannel();

    window.myModuleStatusSubscription = ActionCableConsumer.subscriptions.create(
      { channel: 'MyModuleStatusChannel', my_module_id: myModuleId },
      {
        connected: function() {
          this.perform('sync');
        },
        received: (state) => {
          if ($('#status-container').data('my-module-id') !== myModuleId) return;

          handleStatusState(state);
        }
      }
    );

    $(document).one('turbolinks:before-cache', unsubscribeFromStatusChannel);
  }

  function initStatus() {
    initStatusFlowModal();
    applyTaskStatusChangeCallBack();
    initStatusKeyboard();
    subscribeToStatusChannel();
  }

  initStatus();
}());
