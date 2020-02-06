/* global RepositoryDatatableRowEditor I18n */

(function() {
  'use strict';

  function initUnsavedWorkDialog() {
    $(document).on('turbolinks:before-visit', () => {
      let exit = true;
      let editing = $(`.${RepositoryDatatableRowEditor.EDIT_FORM_CLASS_NAME}`).length > 0;

      if (editing) {
        exit = confirm(I18n.t('repositories.js.leaving_warning'));
      }

      return exit;
    });
  }

  initUnsavedWorkDialog();
}());
