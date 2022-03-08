/* eslint no-underscore-dangle: "off" */
/* eslint no-use-before-define: "off" */
/* eslint no-restricted-syntax: ["off", "BinaryExpression[operator='in']"] */
<<<<<<< HEAD
/* global tinymce I18n HelperModule validateFileSize */
=======
/* global tinymce I18n */
>>>>>>> Finished merging. Test on dev machine (iMac).
(function() {
  'use strict';

  tinymce.PluginManager.requireLangPack('customimageuploader');

  tinymce.create('tinymce.plugins.CustomImageUploader', {
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
      var iframe;
      var win;
      var throbber;
      var editor = ed;
      var textAreaElement = $('#' + ed.id);
      function showDialog() {
        var ctrl;
        var cycle;
        var el;
        var body;
        var containers;
        var inputs;
        win = editor.windowManager.open({
          title: I18n.t('tiny_mce.upload_window_title'),
          width: 520 + parseInt(editor.getLang(
            'customimageuploader.delta_width', 0
          ), 10),
          height: 180 + parseInt(editor.getLang(
            'customimageuploader.delta_height', 0
          ), 10),
          body: [
            { type: 'iframe', url: 'javascript:void(0)' },
            {
              type: 'textbox',
              name: 'file',
              classes: 'image-loader',
              label: I18n.t('tiny_mce.upload_window_label'),
              subtype: 'file'
            },
            {
              type: 'container',
              classes: 'error',
              html: "<p style='color: #b94a48;'>&nbsp;</p>"
            },
            { type: 'container', classes: 'throbber' }
          ],
          buttons: [
            {
              text: I18n.t('tiny_mce.insert_btn'),
              onclick: insertImage,
              subtype: 'primary'
            },
            {
              text: I18n.t('general.cancel'),
              onclick: editor.windowManager.close
            }
          ]
        }, {
          plugin_url: url
        });
        // Let's make image selection looks fancy
        $('<div class="image-selection-container">'
          + '<div class="select_button btn btn-primary">' + I18n.t('tiny_mce.choose_file') + '</div>'
          + '<input type="text" placeholder="' + I18n.t('tiny_mce.no_image_chosen') + '" disabled></input>'
        + '</div>').insertAfter('.mce-image-loader')
          .click(() => { $('.mce-image-loader').click(); })
          .parent()
          .css('height', '32px');

        $('.mce-image-loader')
          .change(e => {
            $(e.target).next().find('input[type=text]')[0].value = e.target.value.split(/(\\|\/)/g).pop();
          })
          .parent().find('label')
          .css('line-height', '32px')
          .css('height', '32px');

        el = win.getEl();
        body = document.getElementById(el.id + '-body');
        containers = body.getElementsByClassName('mce-container');

        win.off('submit');
        win.on('submit', insertImage);

        iframe = win.find('iframe')[0];
        form = createElement('form', {
          action: editor.getParam(
            'customimageuploader_form_url',
            '/tinymce_assets'
          ),
          target: iframe._id,
          method: 'POST',
          enctype: 'multipart/form-data',
          accept_charset: 'UTF-8'
        });
        inputs = form.getElementsByTagName('input');
        iframe.getEl().name = iframe._id;

        // Create some needed hidden inputs
        form.appendChild(
          createElement(
            'input',
            {
              type: 'hidden',
              name: 'utf8',
              value: '✓'
            }
          )
        );
        form.appendChild(
          createElement(
            'input',
            {
              type: 'hidden',
              name: 'authenticity_token',
              value: getMetaContents('csrf-token')
            }
          )
        );
        form.appendChild(
          createElement(
            'input',
            {
              type: 'hidden',
              name: 'object_type',
              value: $(editor.getElement()).data('object-type')
            }
          )
        );
        form.appendChild(
          createElement(
            'input',
            {
              type: 'hidden',
              name: 'object_id',
              value: $(editor.getElement()).data('object-id')
            }
          )
        );
        form.appendChild(
          createElement(
            'input',
            {
              type: 'hidden',
              name: 'hint',
              value: editor.getParam('uploadimage_hint', '')
            }
          )
        );
        for (cycle = 0; cycle < containers.length; cycle += 1) {
          form.appendChild(containers[cycle]);
        }
        for (cycle = 0; cycle < inputs.length; cycle += 1) {
          ctrl = inputs[cycle];

          if (ctrl.tagName.toLowerCase() === 'input' && ctrl.type !== 'hidden') {
            if (ctrl.type === 'file') {
              ctrl.name = 'file';

              tinymce.DOM.setStyles(ctrl, {
                border: 0,
                boxShadow: 'none',
                webkitBoxShadow: 'none'
              });
            } else {
              ctrl.name = 'alt';
            }
          }
        }

        body.appendChild(form);
      }

      function insertImage() {
        var target = iframe.getEl();
        if (getInputValue('file') === '') {
          return handleError(I18n.t('tiny_mce.error_message'));
        }

        throbber = new top.tinymce.ui.Throbber(win.getEl());
        throbber.show(throbber);
        clearErrors();

        /* Add event listeners.
         * We remove the existing to avoid them being called twice in case
         * of errors and re-submitting afterwards.
         */
        if (target.attachEvent) {
          target.detachEvent('onload', uploadDone);
          target.attachEvent('onload', uploadDone);
        } else {
          target.removeEventListener('load', uploadDone);
          target.addEventListener('load', uploadDone, false);
        }

        form.submit();
        return true;
      }

      function uploadDone() {
        var target = iframe.getEl();
        var doc;
        if (throbber) {
          throbber.hide();
        }
        if (target.document || target.contentDocument) {
          doc = target.contentDocument || target.contentWindow.document;
          handleResponse(doc.getElementsByTagName('body')[0].innerHTML);
        } else {
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
        }
      }

      function handleError(error) {
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

        // Small fix for ResultText when you cancel after change MarvinJS
        if (imageContainer === undefined) return [];

=======
>>>>>>> Finished merging. Test on dev machine (iMac).
        imageContainer.value = JSON.stringify(images);
        return JSON.stringify(images);
      }

      // Add a button that opens a window
      editor.addButton('customimageuploader', {
        tooltip: I18n.t('tiny_mce.upload_window_label'),
        icon: 'image',
<<<<<<< HEAD
        onclick: loadFiles
=======
        onclick: showDialog
>>>>>>> Finished merging. Test on dev machine (iMac).
      });

      // Adds a menu item to the tools menu
      editor.addMenuItem('customimageuploader', {
        text: I18n.t('tiny_mce.upload_window_label'),
        icon: 'image',
        context: 'insert',
<<<<<<< HEAD
        onclick: loadFiles
=======
        onclick: showDialog
>>>>>>> Finished merging. Test on dev machine (iMac).
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
