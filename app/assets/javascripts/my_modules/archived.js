(function() {
  let selectedTasks = [];

  $('#module-archive').on('click', '.restore-button-container', function(e) {
    e.preventDefault();
    let restoreForm = $('.restore-button-container').find('form');

    selectedTasks.forEach(function(id) {
      $('<input>').attr({
        type: 'hidden',
        name: 'my_modules_ids[]',
        value: id
      }).appendTo(restoreForm);
    });
    restoreForm.submit();
  });

  $('#module-archive').on('click', '.task-selector', function() {
    let taskId = $(this).closest('.task-selector-container').data('task-id');
    let index = $.inArray(taskId, selectedTasks);
    const restoreTasksButton = $('.restore-button-container');
    const moveTasksButton = $('.move-button-container')

    // If checkbox is checked and row ID is not in list of selected folder IDs
    if (this.checked && index === -1) {
      selectedTasks.push(taskId);
      restoreTasksButton.collapse('show');
      moveTasksButton.collapse('show');
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
    } else if (!this.checked && index !== -1) {
      selectedTasks.splice(index, 1);
    }
    // Hide button
    if (selectedTasks.length === 0) {
      restoreTasksButton.collapse('hide');
      moveTasksButton.collapse('hide');
    }
  });

  function initMoveButton() {
    $('.move-button-container').on('click', 'button', function(e) {
      const cardsContainer = $('#cards-container');
      $.get(cardsContainer.data('move-modules-modal-url'), (modalData) => {
        if ($('#modal-move-modules').length > 0) {
          console.log('replaced');
          $('#modal-move-modules').replaceWith(modalData.html);
        } else {
          $('#module-archive').append(modalData.html);
        }

        $('#modal-move-modules').on('shown.bs.modal', function() {
          $(this).find('.selectpicker').selectpicker().focus();
        });

        $('#modal-move-modules').on('click', 'button[data-action="confirm"]', () => {
          console.log('clicked!')
          const moveParams = {
            to_experiment_id: $('#modal-move-modules').find('.selectpicker').val(),
            my_module_ids: selectedTasks
          };
          $.post(cardsContainer.data('move-modules-url'), moveParams, (data) => {
            HelperModule.flashAlertMsg(data.message, 'success');
            window.location.reload();
          }).error((data) => {
            HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
          });
          $('#modal-move-modules').modal('hide');
        });

        $('#modal-move-modules').modal('show');
        });
    });
  }



  initMoveButton();
}());
