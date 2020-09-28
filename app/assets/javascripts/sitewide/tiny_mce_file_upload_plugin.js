/* eslint no-underscore-dangle: "off" */
/* eslint no-use-before-define: "off" */
/* eslint no-restricted-syntax: ["off", "BinaryExpression[operator='in']"] */
/* global tinymce I18n GLOBAL_CONSTANTS HelperModule*/
(function() {
  'use strict';

  tinymce.PluginManager.requireLangPack('customimageuploader');

  tinymce.create('tinymce.plugins.CustomImageUploader', {
    CustomImageUploader: function(ed) {
      var iframe;
      var editor = ed;
      var textAreaElement = $('#' + ed.id);

      function loadFiles() {
        let $fileInput;
        $('#tinymce_current_upload').remove();
        $(editor.container).prepend('<input type="file" multiple accept="image/*" id="tinymce_current_upload" style="display: none;">');
        $fileInput = $('#tinymce_current_upload');
        $fileInput.click();

        $fileInput.change(function() {
          let formData = new FormData();
          let files = $('#tinymce_current_upload')[0].files;

          Array.from(files).forEach(file => formData.append('files[]', file, file.name));

          $.post({
            url: '/tiny_mce_assets',
            data: formData,
            processData: false,
            contentType: false,
            beforeSend: function(xhr) {
              let sizeLimit = false;
              Array.from(files).forEach(file => {
                if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
                  sizeLimit = true;
                }
              });
              if (sizeLimit) {
                HelperModule.flashAlertMsg(I18n.t('general.file.size_exceeded', { file_size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB }), 'danger');
                xhr.abort();
              }
            },
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
      }

      function handleResponse(response) {
        if (response.errors) {
          handleError(response.errors.join('<br>'));
        } else {
          response.images.forEach(el => editor.execCommand('mceInsertContent', false, buildHTML(el)));
          updateActiveImages(ed);
        }
      }

      function handleError(error) {
        HelperModule.flashAlertMsg(error, 'danger');
      }

      function buildHTML(image) {
        var imgstr = "<img src='" + image.url + "'";
        imgstr += " data-mce-token='" + image.token + "'";
        imgstr += " alt='description-" + image.token + "' />";
        return imgstr;
      }

      // Create hidden field for images
      function createImageHiddenField() {
        textAreaElement.parent().find('input#tiny-mce-images').remove();
        $('<input type="hidden" id="tiny-mce-images" name="tiny_mce_images" value="[]">').insertAfter(textAreaElement);
      }

      // Finding images in text
      function updateActiveImages() {
        var images;
        var imageContainer = $('#' + editor.id).next()[0];
        iframe = $('#' + editor.id).prev().find('.mce-edit-area iframe').contents();
        images = $.map($('img', iframe), e => {
          return e.dataset.mceToken;
        });
        if (imageContainer === undefined) {
          createImageHiddenField();
        }

        // Small fix for ResultText when you cancel after change MarvinJS
        if (imageContainer === undefined) return [];

        imageContainer.value = JSON.stringify(images);
        return JSON.stringify(images);
      }

      // Add a button that opens a window
      editor.addButton('customimageuploader', {
        tooltip: I18n.t('tiny_mce.upload_window_label'),
        icon: 'image',
        onclick: loadFiles
      });

      // Adds a menu item to the tools menu
      editor.addMenuItem('customimageuploader', {
        text: I18n.t('tiny_mce.upload_window_label'),
        icon: 'image',
        context: 'insert',
        onclick: loadFiles
      });

      ed.on('NodeChange', function() {
        // Check editor status
        if (this.initialized) {
          updateActiveImages(ed);
        }
      });

      createImageHiddenField();
    }


  });

  tinymce.PluginManager.add(
    'customimageuploader',
    tinymce.plugins.CustomImageUploader
  );
}());
