/* global _ hljs tinyMCE SmartAnnotation */

var TinyMCE = (function() {
  'use strict';

  function initHighlightjs() {
    $('[class*=language]').each(function(i, block) {
      hljs.highlightBlock(block);
    });
  }

  function initHighlightjsIframe(iframe) {
    $('[class*=language]', iframe).each(function(i, block) {
      hljs.highlightBlock(block);
    });
  }

  // returns a public API for TinyMCE editor
  return Object.freeze({
    init: function(selector) {
      if (typeof tinyMCE !== 'undefined') {
        tinyMCE.init({
          cache_suffix: '?v=4.9.3', // This suffix should be changed any time library is updated
          selector: selector,
          menubar: 'file edit view insert format',
          toolbar: 'undo redo restoredraft | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link | forecolor backcolor | customimageuploader | codesample',
          plugins: 'autosave autoresize customimageuploader link advlist codesample autolink lists charmap hr anchor searchreplace wordcount visualblocks visualchars insertdatetime nonbreaking save directionality paste textcolor colorpicker textpattern',
          codesample_languages: [
            { text: 'R', value: 'r' },
            { text: 'MATLAB', value: 'matlab' },
            { text: 'Python', value: 'python' },
            { text: 'JSON', value: 'javascript' },
            { text: 'HTML/XML', value: 'markup' },
            { text: 'JavaScript', value: 'javascript' },
            { text: 'CSS', value: 'css' },
            { text: 'PHP', value: 'php' },
            { text: 'Ruby', value: 'ruby' },
            { text: 'Java', value: 'java' },
            { text: 'C', value: 'c' },
            { text: 'C#', value: 'csharp' },
            { text: 'C++', value: 'cpp' }
          ],
          browser_spellcheck: true,
          branding: false,
          fixed_toolbar_container: '#mytoolbar',
          autosave_interval: '15s',
          autosave_retention: '1440m',
          removed_menuitems: 'newdocument',
          object_resizing: false,
          elementpath: false,
          forced_root_block: false,
          default_link_target: '_blank',
          target_list: [
            { title: 'New page', value: '_blank' },
            { title: 'Same page', value: '_self' }
          ],
          style_formats: [
            {
              title: 'Headers',
              items: [
                { title: 'Header 1', format: 'h1' },
                { title: 'Header 2', format: 'h2' },
                { title: 'Header 3', format: 'h3' },
                { title: 'Header 4', format: 'h4' },
                { title: 'Header 5', format: 'h5' },
                { title: 'Header 6', format: 'h6' }
              ]
            },
            {
              title: 'Inline',
              items: [
                { title: 'Bold', icon: 'bold', format: 'bold' },
                { title: 'Italic', icon: 'italic', format: 'italic' },
                { title: 'Underline', icon: 'underline', format: 'underline' },
                { title: 'Strikethrough', icon: 'strikethrough', format: 'strikethrough' },
                { title: 'Superscript', icon: 'superscript', format: 'superscript' },
                { title: 'Subscript', icon: 'subscript', format: 'subscript' },
                { title: 'Code', icon: 'code', format: 'code' }
              ]
            },
            {
              title: 'Blocks',
              items: [
                { title: 'Paragraph', format: 'p' },
                { title: 'Blockquote', format: 'blockquote' }
              ]
            },
            {
              title: 'Alignment',
              items: [
                { title: 'Left', icon: 'alignleft', format: 'alignleft' },
                { title: 'Center', icon: 'aligncenter', format: 'aligncenter' },
                { title: 'Right', icon: 'alignright', format: 'alignright' },
                { title: 'Justify', icon: 'alignjustify', format: 'alignjustify' }
              ]
            }
          ],
          init_instance_callback: function(editor) {
            SmartAnnotation.init($(editor.contentDocument.activeElement));
            initHighlightjsIframe($(this.iframeElement).contents());
          },
          setup: function(editor) {
            editor.on('keydown', function(e) {
              if (e.keyCode === 13 && $(editor.contentDocument.activeElement).atwho('isSelecting')) {
                return false;
              }
              return true;
            });

            editor.on('NodeChange', function(e) {
              var node = e.element;
              setTimeout(function() {
                if ($(node).is('pre') && !editor.isHidden()) {
                  initHighlightjsIframe($(editor.iframeElement).contents());
                }
              }, 200);
            });

            editor.on('init', function() {
              var editorForm = $(editor.getContainer()).closest('form');
              var menuBar = editorForm.find('.mce-menubar.mce-toolbar.mce-first .mce-flow-layout');

              // Init saved status label
              if (editor.getContent() !== '') {
                editorForm.find('.tinymce-status-badge').removeClass('hidden');
              }

              // Init Save button
              editorForm
                .find('.tinymce-save-button')
                .clone()
                .appendTo(menuBar)
                .on('click', function(event) {
                  event.preventDefault();
                  editorForm.clearFormErrors();
                  editor.setProgressState(1);
                  editor.save();
                  editorForm.submit();
                });

              // After save action
              editorForm
                .on('ajax:success', function() {
                  editor.save();
                  editor.setProgressState(0);
                  editorForm.find('.tinymce-status-badge').removeClass('hidden');
                  editor.remove();
                }).on('ajax:error', function(ev, data) {
                  var model = editor.getElement().dataset.objectType;
                  $(this).renderFormErrors(model, data.responseJSON);
                  editor.setProgressState(0);
                });

              // Init Cancel button
              editorForm
                .find('.tinymce-cancel-button')
                .clone()
                .appendTo(menuBar)
                .on('click', function(event) {
                  event.preventDefault();
                  if (editor.isDirty()) {
                    editor.setContent($(selector).val());
                  }
                  editor.remove();
                })
                .removeClass('hidden');
            });

            editor.on('Dirty', function() {
              var editorForm = $(editor.getContainer()).closest('form');
              editorForm.find('.tinymce-status-badge').addClass('hidden');
              $(editor.getContainer())
                .find('.tinymce-save-button').removeClass('hidden');
            });

            editor.on('remove', function() {
              var menuBar = $(editor.getContainer()).find('.mce-menubar.mce-toolbar.mce-first .mce-flow-layout');
              menuBar.find('.tinymce-save-button').remove();
              menuBar.find('.tinymce-cancel-button').remove();
            });
          },
          codesample_content_css: $(selector).data('highlightjs-path')
        });
      }
    },
    destroyAll: function() {
      _.each(tinyMCE.editors, function(editor) {
        if (editor) {
          editor.destroy();
          initHighlightjs();
        }
      });
    },
    refresh: function() {
      this.destroyAll();
      this.init();
    },
    getContent: function() {
      return tinyMCE.editors[0].getContent();
    },
    highlight: initHighlightjs
  });
}());
