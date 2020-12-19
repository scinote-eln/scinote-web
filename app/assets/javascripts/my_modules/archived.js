(function() {
  let selectedTasks = [];

  $('#module-archive').on('click', '.restore-button', function(e) {
    let resoteTasksButtonContainer = $(this).closest('.restore-button-container');

    $.ajax({
      url: $(this).data('archive-tasks-url'),
      type: 'PATCH',
      dataType: 'json',
      data: {
        restore_task_ids: selectedTasks,
      },
      success: function(data) {
        HelperModule.flashAlertMsg(data.message, 'success');
        $.each(selectedTasks, function(i, id) {
          $(`.module-container [data-task-id=${id}]`).closest('.module-container').remove();
        });
        selectedTasks = [];
        resoteTasksButtonContainer.collapse('hide')
      },
      error: function(response) {
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        } else {
          HelperModule.flashAlertMsg(
            response.responseJSON.message + ' ' + response.responseJSON.errors, 'danger');
        }
      }
    });
  });

  $('#module-archive').on('click', '.task-selector', function() {
    let taskId = $(this).closest('.task-selector-container').data('task-id');
    let index = $.inArray(taskId, selectedTasks);
    let resoteTasksButtonContainer = $('.restore-button-container');

    // If checkbox is checked and row ID is not in list of selected folder IDs
    if (this.checked && index === -1) {
      selectedTasks.push(taskId);
      resoteTasksButtonContainer.collapse('show');
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
    } else if (!this.checked && index !== -1) {
      selectedTasks.splice(index, 1);
    }
    // Hide button
    if (selectedTasks.length === 0) resoteTasksButtonContainer.collapse('hide');
  });
}());
