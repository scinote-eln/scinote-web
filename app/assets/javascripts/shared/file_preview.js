/* global ActiveStoragePreviews HelperModule I18n */

(function() {
  $('.asset-image')
    .on('load', (event) => ActiveStoragePreviews.showPreview(event))
    .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event));

  $('.file-metadata-flyout').on('click', (e) => e.stopPropagation());

  function saveFileTitle($input) {
    var newTitle = $input.val().trim();

    if (newTitle === $input.data('original-value')) return;

    if (newTitle.length > 50) {
      HelperModule.flashAlertMsg(
        I18n.t('assets.file_preview.file_title_max_length_error', { max_length: FILE_TITLE_MAX_LENGTH }),
        'danger'
      );
      $input.val($input.data('original-value'));
      return;
    }

    $input.prop('disabled', true);
    $.ajax({
      url: $input.data('update-url'),
      type: 'PATCH',
      dataType: 'json',
      data: { asset: { file_title: newTitle } },
      success: function(result) {
        $input.data('original-value', newTitle);
        $input.val(newTitle);
      },
      error: function() {
        HelperModule.flashAlertMsg(I18n.t('errors.general'), 'danger');
      },
      complete: function() {
        $input.prop('disabled', false);
      }
    });
  }

  $('.file-title-input').each(function() {
    $(this).data('original-value', $(this).val());
  });

  $(document)
    .off('blur', '.file-title-input')
    .off('keydown', '.file-title-input')
    .on('blur', '.file-title-input', function() {
      saveFileTitle($(this));
    })
    .on('keydown', '.file-title-input', function(e) {
      if (e.keyCode === 13) {
        e.preventDefault();
        $(this).trigger('blur');
      }
    });
}());
