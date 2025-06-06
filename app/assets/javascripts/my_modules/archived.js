/* global HelperModule */

(function() {
  let selectedTasks = [];

  $('#module-archive').on('click', '.task-selector', function() {
    let taskId = $(this).closest('.task-selector-container').data('task-id');
    let index = $.inArray(taskId, selectedTasks);

    // If checkbox is checked and row ID is not in list of selected folder IDs
    if (this.checked && index === -1) {
      selectedTasks.push(taskId);
    } else if (!this.checked && index !== -1) {
      selectedTasks.splice(index, 1);
    }

    const items = selectedTasks.length ? JSON.stringify(selectedTasks.map((item) => ({ id: item }))) : [];
    window.actionToolbarComponent.fetchActions({ items });
  });

  function restoreMyModules(url, ids) {
    $.post(url, { my_modules_ids: ids, view: 'cards' }, () => {
      window.location.reload();
    });
  }

  function initRestoreMyModules() {
    $('#module-archive').on('click', '#restoreTask', (e) => {
      $('#restoreTask').addClass('disable-click');
      e.stopPropagation();
      restoreMyModules(e.currentTarget.dataset.url, selectedTasks);
    });
  }

  function initMoveButton() {
    $('#module-archive').on('click', '#moveTask', function(e) {
      e.preventDefault();

      const cardsContainer = $('#cards-container');
      $.get(cardsContainer.data('move-modules-modal-url'), (modalData) => {
        if ($('#modal-move-modules').length > 0) {
          $('#modal-move-modules').replaceWith(modalData.html);
        } else {
          $('#module-archive').append(modalData.html);
        }

        $('#modal-move-modules').on('shown.bs.modal', function() {
          $(this).find('.selectpicker').selectpicker().focus();
        });

        $('#modal-move-modules').on('click', 'button[data-action="confirm"]', () => {
          $('#modal-move-modules button[data-action="confirm"]').addClass('disable-click');

          const moveParams = {
            to_experiment_id: $('#modal-move-modules').find('.selectpicker').val(),
            my_module_ids: selectedTasks
          };
          $.post(cardsContainer.data('move-modules-url'), moveParams, (data) => {
            HelperModule.flashAlertMsg(data.message, 'success');
            window.location.reload();
          }).fail((data) => {
            $('#modal-move-modules button[data-action="confirm"]').removeClass('disable-click');
            HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
          });
          $('#modal-move-modules').modal('hide');
        });

        $('#modal-move-modules').modal('show');
      });
    });
  }

  function initAccessModal() {
    $('#module-archive').on('click', '#openAccessModal', (e) => {
      e.preventDefault();
      const container = document.getElementById('accessModalContainer');
      const target = e.currentTarget;

      $.get(target.dataset.url, (data) => {
        const object = {
          ...data.data.attributes,
          id: data.data.id,
          type: data.data.type
        };
        const { rolesUrl } = container.dataset;
        const params = {
          object,
          roles_path: rolesUrl
        };
        const modal = $('#accessModalComponent').data('accessModal');
        modal.params = params;
        modal.open();
      });
    });
  }

  window.initActionToolbar();
  initRestoreMyModules();
  initMoveButton();
  initAccessModal();
}());
