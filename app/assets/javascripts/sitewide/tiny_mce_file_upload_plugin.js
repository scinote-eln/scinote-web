(function() {
  'use strict';

  tinymce.PluginManager.requireLangPack('customimageuploader');

  tinymce.create('tinymce.plugins.CustomImageUploader', {
    CustomImageUploader: function(ed, url) {
      var form, iframe, win, throbber, editor = ed;
      function showDialog() {
        win = editor.windowManager.open({
          title: $('#locale_data').attr('data-TINYMCE_UPLOAD_WINDOW_TITLE'),
          width: 520 + parseInt(editor.getLang(
                                         'customimageuploader.delta_width', 0
                                       ), 10),
          height: 180 + parseInt(editor.getLang(
                                          'customimageuploader.delta_height', 0
                                        ), 10),
          body: [
            {type: 'iframe', url: 'javascript:void(0)'},
            {type: 'textbox',
             name: 'file',
             label: $('#locale_data').attr('data-TINYMCE_UPLOAD_WINDOW_LABEL'),
             subtype: 'file'},
            {type: 'container',
             classes: 'error',
             html: "<p style='color: #b94a48;'>&nbsp;</p>"},
            {type: 'container', classes: 'throbber'},
          ],
          buttons: [
            {text: $('#locale_data').attr('data-TINYMCE_INSERT_BTN'),
             onclick: insertImage,
             subtype: 'primary'},
            {text: $('#locale_data').attr('data-GENERAL_CANCEL'),
             onclick: editor.windowManager.close}
          ],
        }, {
          plugin_url: url
        });

        win.off('submit');
        win.on('submit', insertImage);

        iframe = win.find('iframe')[0];
        form = createElement('form', {
          action: editor.getParam('customimageuploader_form_url',
                                  $('#rails_route_data').attr('data-RAILS_URL_HELPER_TINY_MCE_ASSETS_PATH')),
          target: iframe._id,
          method: 'POST',
          enctype: 'multipart/form-data',
          accept_charset: 'UTF-8',
        });

        iframe.getEl().name = iframe._id;

        // Create some needed hidden inputs
        form.appendChild(createElement('input',
                                       {type: 'hidden',
                                        name: 'utf8',
                                        value: '✓'}));
        form.appendChild(createElement('input',
                                       {type: 'hidden',
                                        name: 'authenticity_token',
                                        value: getMetaContents('csrf-token')}));
        form.appendChild(createElement('input',
                                       {type: 'hidden',
                                        name: 'object_type',
                                        value: $(editor.getElement())
                                                       .data('object-type')}));
        form.appendChild(createElement('input',
                                       {type: 'hidden',
                                        name: 'object_id',
                                        value: $(editor.getElement())
                                                       .data('object-id')}));
        form.appendChild(createElement('input',
                         {type: 'hidden',
                          name: 'hint',
                          value: editor.getParam('uploadimage_hint', '')}));

        var el = win.getEl();
        var body = document.getElementById(el.id + '-body');

        // Copy everything TinyMCE made into our form
        var containers = body.getElementsByClassName('mce-container');
        for(var i = 0; i < containers.length; i++) {
          form.appendChild(containers[i]);
        }

        var inputs = form.getElementsByTagName('input');
        for(var i = 0; i < inputs.length; i++) {
          var ctrl = inputs[i];

          if(ctrl.tagName.toLowerCase() == 'input' && ctrl.type != 'hidden') {
            if(ctrl.type == 'file') {
              ctrl.name = 'file';

              tinymce.DOM.setStyles(ctrl, {
                'border': 0,
                'boxShadow': 'none',
                'webkitBoxShadow': 'none',
              });
            } else {
              ctrl.name = 'alt';
            }
          }
        }

        body.appendChild(form);
      }

      function insertImage() {
        if(getInputValue('file') == '') {
          return handleError($('#locale_data').attr('data-TINYMCE_ERROR_MESSAGE'));
        }

        throbber = new top.tinymce.ui.Throbber(win.getEl());
        throbber.show();

        clearErrors();

        /* Add event listeners.
         * We remove the existing to avoid them being called twice in case
         * of errors and re-submitting afterwards.
         */
        var target = iframe.getEl();
        if(target.attachEvent) {
          target.detachEvent('onload', uploadDone);
          target.attachEvent('onload', uploadDone);
        } else {
          target.removeEventListener('load', uploadDone);
          target.addEventListener('load', uploadDone, false);
        }

        form.submit();
      }

      function uploadDone() {
        if(throbber) {
          throbber.hide();
        }

        var target = iframe.getEl();
        if(target.document || target.contentDocument) {
          var doc = target.contentDocument || target.contentWindow.document;
          handleResponse(doc.getElementsByTagName("body")[0].innerHTML);
        } else {
          handleError($('#locale_data').attr('data-TINYMCE_SERVER_NOT_RESPONDED'));
        }
      }

      function handleResponse(ret) {
        try {
          var json = tinymce.util.JSON.parse(ret);

          if(json['error']) {
            handleError(json['error']['message']);
          } else {
            editor.execCommand('mceInsertContent', false, buildHTML(json));
            editor.windowManager.close();
          }
        } catch(e) {
          // hack that gets the server error message
          var error_json = JSON.parse($(ret).text());
          handleError(error_json['error'][0]);
        }
      }

      function clearErrors() {
        var message = win.find('.error')[0].getEl();

        if(message)
          message.getElementsByTagName('p')[0].innerHTML = '&nbsp;';
      }

      function handleError(error) {
        var message = win.find('.error')[0].getEl();

        if(message) {
          message
            .getElementsByTagName('p')[0]
            .innerHTML = editor.translate(error);
        }

      }

      function createElement(element, attributes) {
        var el = document.createElement(element);
        for(var property in attributes) {
          if (!(attributes[property] instanceof Function)) {
            el[property] = attributes[property];
          }
        }

        return el;
      }

      function buildHTML(json) {
        var imgstr = "<img src='" + json['image']['url'] + "'";
        imgstr += " data-token='" + json['image']['token'] + "'"
        imgstr += " alt='description-" + json['image']['token'] + "'/>";
        return imgstr;
      }

      function getInputValue(name) {
        var inputs = form.getElementsByTagName('input');

        for(var i in inputs)
          if(inputs[i].name == name)
            return inputs[i].value;

        return "";
      }

      function getMetaContents(mn) {
        var m = document.getElementsByTagName('meta');

        for(var i in m)
          if(m[i].name == mn)
            return m[i].content;

        return null;
      }

      // Add a button that opens a window
      editor.addButton('customimageuploader', {
        tooltip: $('#locale_data').attr('data-TINYMCE_UPLOAD_WINDOW_LABEL'),
        icon: 'image',
        onclick: showDialog
      });

      // Adds a menu item to the tools menu
      editor.addMenuItem('customimageuploader', {
        text: $('#locale_data').attr('data-TINYMCE_UPLOAD_WINDOW_LABEL'),
        icon: 'image',
        context: 'insert',
        onclick: showDialog
      });
    }
  });

  tinymce.PluginManager.add('customimageuploader',
                            tinymce.plugins.CustomImageUploader);
})();
