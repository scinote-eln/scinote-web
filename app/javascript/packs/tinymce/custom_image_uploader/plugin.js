/* eslint no-underscore-dangle: "off" */
/* eslint no-use-before-define: "off" */
/* eslint no-restricted-syntax: ["off", "BinaryExpression[operator='in']"] */
/* global tinymce I18n HelperModule validateFileSize */

import { rails_direct_uploads_path } from '../../../routes';

tinymce.PluginManager.add('customimageuploader', (editor) => {
  var iframe;
  var textAreaElement = $('#' + editor.id);

  function loadFiles() {
    let $fileInput;
    let hitFileLimit;
    $('#tinymce_current_upload').remove();
    $fileInput = $('<input type="file" multiple accept="image/*" id="tinymce_current_upload" style="display: none;">')
      .prependTo(editor.container);
    $fileInput.click();

    $fileInput.change(function() {
      let files = $('#tinymce_current_upload')[0].files;

      Array.from(files).every(file => {
        if (!validateFileSize(file, true)) {
          hitFileLimit = true;
          return false;
        }
      });

      if (hitFileLimit) {
        return;
      }

      let uploads = Array.from(files).map(file => {
        const upload = new ActiveStorage.DirectUpload(file, rails_direct_uploads_path());

        return new Promise((resolve, reject) => {
          upload.create((error, blob) => {
            if (error) {
              HelperModule.flashAlertMsg(`Upload failed: ${error}`, 'danger');
              reject(error);
            } else {
              resolve({ blob_id: blob.signed_id });
            }
          });
        });
      });

      Promise.all(uploads).then(uploadedBlobs => {
        $.post({
          url: textAreaElement.data('tinymce-asset-path'),
          contentType: 'application/json',
          data: JSON.stringify({ files: uploadedBlobs }),
          processData: false,
          success: function(data) {
            handleResponse(data);
            $('#tinymce_current_upload').remove();
          },
          error: function(response) {
            HelperModule.flashAlertMsg(response.responseJSON.errors, 'danger');
            $('#tinymce_current_upload').remove();
          }
        });
      });
    });
  }

  function handleResponse(response) {
    if (response.errors) {
      handleError(response.errors.join('<br>'));
    } else {
      response.images.forEach(el => editor.execCommand('mceInsertContent', false, buildHTML(el)));
      updateActiveImages();
    }
  }

  function handleError(error) {
    HelperModule.flashAlertMsg(error, 'danger');
  }

  function buildHTML(image) {
    return `<img src="${image.url}"
                 data-mce-token="${image.token}"
                 alt="description-${image.token}" />`;
  }

  // Create hidden field for images
  function createImageHiddenField() {
    textAreaElement.parent().find('input.tiny-mce-images').remove();
    $('<input type="hidden" class="tiny-mce-images" name="tiny_mce_images" value="[]">').appendTo(textAreaElement.parent());
  }

  // Finding images in text
  function updateActiveImages() {
    const imageContainer = $(`#${editor.id}`).parent().find('input.tiny-mce-images');
    iframe = $(`#${editor.id}`).next().find('.tox-edit-area iframe').contents();
    const images = $.map($('img', iframe), e => e.dataset.mceToken);
    if (imageContainer === undefined) {
      createImageHiddenField();
    }

    // Small fix for ResultText when you cancel after change MarvinJS
    if (imageContainer === undefined) return [];

    imageContainer.val(JSON.stringify(images));
    return JSON.stringify(images);
  }

  // Add a button that opens a window
  editor.ui.registry.addButton('customimageuploader', {
    tooltip: I18n.t('tiny_mce.upload_window_label'),
    icon: 'image',
    onAction: loadFiles
  });

  // Adds a menu item to the tools menu
  editor.ui.registry.addMenuItem('customimageuploader', {
    text: I18n.t('tiny_mce.upload_window_label'),
    icon: 'image',
    context: 'insert',
    onAction: loadFiles
  });

  editor.on('NodeChange', function() {
    // Check editor status
    if (this.initialized) {
      updateActiveImages();
    }
  });

  createImageHiddenField();

  return {
    getMetadata: () => ({
      name: 'Custom Image Uploader Plugin'
    })
  };
});
