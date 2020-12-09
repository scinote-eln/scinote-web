/* eslint no-underscore-dangle: "off" */
/* eslint no-use-before-define: "off" */
/* eslint no-restricted-syntax: ["off", "BinaryExpression[operator='in']"] */
<<<<<<< HEAD
<<<<<<< HEAD
/* global tinymce I18n HelperModule validateFileSize */
=======
/* global tinymce I18n */
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
/* global tinymce I18n HelperModule validateFileSize */
>>>>>>> Pulled latest release
(function() {
  'use strict';

  tinymce.PluginManager.requireLangPack('customimageuploader');

  tinymce.create('tinymce.plugins.CustomImageUploader', {
<<<<<<< HEAD
<<<<<<< HEAD
    CustomImageUploader: function(ed) {
      var iframe;
      var editor = ed;
      var textAreaElement = $('#' + ed.id);

      function loadFiles() {
        let $fileInput;
        let hitFileLimit;
        $('#tinymce_current_upload').remove();
        $fileInput = $('<input type="file" multiple accept="image/*" id="tinymce_current_upload" style="display: none;">').prependTo(editor.container);
        $fileInput.click();

        $fileInput.change(function() {
          let formData = new FormData();
          let files = $('#tinymce_current_upload')[0].files;

          Array.from(files).forEach(file => formData.append('files[]', file, file.name));

          Array.from(files).every(file => {
            if (!validateFileSize(file, true)) {
              hitFileLimit = true;
              return false;
            }
          });

          if (hitFileLimit) {
            return;
          }

          $.post({
            url: textAreaElement.data('tinymce-asset-path'),
            data: formData,
            processData: false,
            contentType: false,
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
=======
    CustomImageUploader: function(ed, url) {
      var form;
=======
    CustomImageUploader: function(ed) {
>>>>>>> Pulled latest release
      var iframe;
      var editor = ed;
      var textAreaElement = $('#' + ed.id);

      function loadFiles() {
        let $fileInput;
        let hitFileLimit;
        $('#tinymce_current_upload').remove();
        $fileInput = $('<input type="file" multiple accept="image/*" id="tinymce_current_upload" style="display: none;">').prependTo(editor.container);
        $fileInput.click();

        $fileInput.change(function() {
          let formData = new FormData();
          let files = $('#tinymce_current_upload')[0].files;

          Array.from(files).forEach(file => formData.append('files[]', file, file.name));

          Array.from(files).every(file => {
            if (!validateFileSize(file, true)) {
              hitFileLimit = true;
              return false;
            }
          });

          if (hitFileLimit) {
            return;
          }

          $.post({
            url: textAreaElement.data('tinymce-asset-path'),
            data: formData,
            processData: false,
            contentType: false,
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
<<<<<<< HEAD
          handleError(I18n.t('tiny_mce.server_not_respond'));
        }
      }

      function handleResponse(ret) {
        var json;
        var errorJson;
        try {
          json = tinymce.util.JSON.parse(ret);

          if (json.error) {
            handleError(json.error.message);
          } else {
            editor.execCommand('mceInsertContent', false, buildHTML(json));
            editor.windowManager.close();
            updateActiveImages(ed);
          }
        } catch (e) {
          // hack that gets the server error message
          errorJson = JSON.parse($(ret).text());
          handleError(errorJson.error[0]);
        }
      }

      function clearErrors() {
        var message = win.find('.error')[0].getEl();

        if (message) {
          message.getElementsByTagName('p')[0].innerHTML = '&nbsp;';
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
          response.images.forEach(el => editor.execCommand('mceInsertContent', false, buildHTML(el)));
          updateActiveImages(ed);
>>>>>>> Pulled latest release
        }
      }

      function handleError(error) {
<<<<<<< HEAD
<<<<<<< HEAD
        HelperModule.flashAlertMsg(error, 'danger');
      }

      function buildHTML(image) {
        return `<img src="${image.url}" 
                     data-mce-token="${image.token}" 
                     alt="description-${image.token}" />`;
=======
        var message = win.find('.error')[0].getEl();

        if (message) {
          message
            .getElementsByTagName('p')[0]
            .innerHTML = editor.translate(error);
        }
      }
      function createElement(element, attributes) {
        var elResult = document.createElement(element);
        var property;
        for (property in attributes) {
          if (!(attributes[property] instanceof Function)) {
            elResult[property] = attributes[property];
          }
        }
        return elResult;
      }

      function buildHTML(json) {
        var imgstr = "<img src='" + json.image.url + "'";
        imgstr += " data-mce-token='" + json.image.token + "'";
        imgstr += " alt='description-" + json.image.token + "' />";
        return imgstr;
      }

      function getInputValue(name) {
        var inputValues = form.getElementsByTagName('input');
        var cycle;

        for (cycle in inputValues) {
          if (inputValues[cycle].name === name) {
            return inputValues[cycle].value;
          }
        }
        return '';
      }

      function getMetaContents(mn) {
        var m = document.getElementsByTagName('meta');
        var cycle;

        for (cycle in m) {
          if (m[cycle].name === mn) {
            return m[cycle].content;
          }
        }

        return null;
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
        HelperModule.flashAlertMsg(error, 'danger');
      }

      function buildHTML(image) {
        return `<img src="${image.url}" 
                     data-mce-token="${image.token}" 
                     alt="description-${image.token}" />`;
>>>>>>> Pulled latest release
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
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Initial commit of 1.17.2 merge

        // Small fix for ResultText when you cancel after change MarvinJS
        if (imageContainer === undefined) return [];

<<<<<<< HEAD
=======
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Initial commit of 1.17.2 merge
        imageContainer.value = JSON.stringify(images);
        return JSON.stringify(images);
      }

      // Add a button that opens a window
      editor.addButton('customimageuploader', {
        tooltip: I18n.t('tiny_mce.upload_window_label'),
        icon: 'image',
<<<<<<< HEAD
<<<<<<< HEAD
        onclick: loadFiles
=======
        onclick: showDialog
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
        onclick: loadFiles
>>>>>>> Pulled latest release
      });

      // Adds a menu item to the tools menu
      editor.addMenuItem('customimageuploader', {
        text: I18n.t('tiny_mce.upload_window_label'),
        icon: 'image',
        context: 'insert',
<<<<<<< HEAD
<<<<<<< HEAD
        onclick: loadFiles
=======
        onclick: showDialog
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
        onclick: loadFiles
>>>>>>> Pulled latest release
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
