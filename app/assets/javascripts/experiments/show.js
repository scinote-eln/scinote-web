/* global dropdownSelector initBSTooltips I18n */

(function() {
  function initNewMyModuleModal() {
    $('#experiment-canvas').on('click', '.new-my-module-button', (e) => {
      $('#newTaskModalComponent').data('newTaskModal').open();
      e.preventDefault();
    });
  }

  function initAccessModal() {
    $('#experiment-canvas').on('click', '.openAccessModal', (e) => {
      e.preventDefault();
      const { target } = e;
      $.get(target.dataset.url, (data) => {
        const object = {
          ...data.data.attributes,
          id: data.data.id,
          type: data.data.type
        };
        const { rolesUrl } = target.dataset;
        const params = {
          object: object,
          roles_path: rolesUrl
        };
        const modal = $('#accessModalComponent').data('accessModal');
        modal.params = params;
        modal.open();
      });
    });
  }

  initNewMyModuleModal();
  initAccessModal();
}());
