/* global GLOBAL_CONSTANTS I18n */

(function() {
  'use strict';

  function initUnsavedWorkDialog() {
    $(document).on('turbolinks:before-visit', () => {
      let exit = true;
      let editing = $(`.${GLOBAL_CONSTANTS.REPOSITORY_ROW_EDITOR_FORM_CLASS_NAME}`).length > 0;

      if (editing) {
        exit = confirm(I18n.t('repositories.js.leaving_warning'));
      }

      return exit;
    });
  }

  initUnsavedWorkDialog();
}());
