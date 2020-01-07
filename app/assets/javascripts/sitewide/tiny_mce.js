/* global _ hljs tinyMCE SmartAnnotation I18n GLOBAL_CONSTANTS */
/* eslint-disable no-unused-vars */

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

  // Get LocalStorage auto save path
  function getAutoSavePrefix(editor) {
    var prefix = editor.getParam('autosave_prefix', 'tinymce-autosave-{path}{query}{hash}-{id}-');

    prefix = prefix.replace(/\{path\}/g, document.location.pathname);
    prefix = prefix.replace(/\{query\}/g, document.location.search);
    prefix = prefix.replace(/\{hash\}/g, document.location.hash);
    prefix = prefix.replace(/\{id\}/g, editor.id);

    return prefix;
  }

  // Handles autosave notification if draft is available in the local storage
  function restoreDraftNotification(selector, editor) {
    var prefix = getAutoSavePrefix(editor);
    var lastDraftTime = parseInt(tinyMCE.util.LocalStorage.getItem(prefix + 'time'), 10);
    var lastUpdated = $(selector).data('last-updated');
    var notificationBar;
    var restoreBtn = $('<button class="btn restore-draft-btn">Restore Draft</button>');
    var cancelBtn = $('<span class="fas fa-times"></span>');

    // Check whether we have draft stored
    if (editor.plugins.autosave.hasDraft()) {
      notificationBar = $('<div class="restore-draft-notification"></div>');

      if (lastDraftTime < lastUpdated) {
        notificationBar.html(`<span class="notification-text">${I18n.t('tiny_mce.older_version_available')}</span>`);
      } else {
        notificationBar.html(`<span class="notification-text">${I18n.t('tiny_mce.newer_version_available')}</span>`);
      }

      // Add notification bar
      $(notificationBar).append(restoreBtn).append(cancelBtn);
      $(editor.contentAreaContainer).before(notificationBar);

      $(restoreBtn).click(function() {
        editor.plugins.autosave.restoreDraft();
        makeItDirty(editor);
        notificationBar.remove();
      });

      $(cancelBtn).click(function() {
        notificationBar.remove();
      });
    }
  }

  function initImageToolBar(editor) {
    var editorIframe = $('#' + editor.id).prev().find('.mce-edit-area iframe');
    editorIframe.contents().find('head').append('<style type="text/css">'
      + 'img::-moz-selection{background:0 0}'
      + 'img::selection{background:0 0}'
      + '.mce-content-body img[data-mce-selected]{outline:2px solid #37a0d9}'
      + '.mce-content-body div.mce-resizehandle{background:transparent;border-color:transparent;box-sizing:border-box;height:10px;width:10px}'
      + '.mce-content-body div.mce-resizehandle:hover{background:transparent}'
      + '.mce-content-body div#mceResizeHandlenw{border-left: 2px solid #37a0d9; border-top: 2px solid #37a0d9}'
      + '.mce-content-body div#mceResizeHandlene{border-right: 2px solid #37a0d9; border-top: 2px solid #37a0d9}'
      + '.mce-content-body div#mceResizeHandlesw{border-left: 2px solid #37a0d9; border-bottom: 2px solid #37a0d9}'
      + '.mce-content-body div#mceResizeHandlese{border-right: 2px solid #37a0d9; border-bottom: 2px solid #37a0d9}'
      + '</style>');
  }

  function makeItDirty(editor) {
    var editorForm = $(editor.getContainer()).closest('form');
    editorForm.find('.tinymce-status-badge').addClass('hidden');
    $(editor.getContainer()).find('.tinymce-save-button').removeClass('hidden');
  }

  // returns a public API for TinyMCE editor
  return Object.freeze({
    init: function(selector, onSaveCallback) {
      var tinyMceContainer;
      var tinyMceInitSize;
      var plugins;
      var textAreaObject = $(selector);
      if (typeof tinyMCE !== 'undefined') {
        // Hide element containing HTML view of RTE field
        tinyMceContainer = $(selector).closest('form').find('.tinymce-view');
        tinyMceInitSize = tinyMceContainer.height();
        $(selector).closest('.form-group')
          .before('<div class="tinymce-placeholder" style="height:' + tinyMceInitSize + 'px"></div>');
        tinyMceContainer.addClass('hidden');
        plugins = 'custom_image_toolbar autosave autoresize customimageuploader link advlist codesample autolink lists charmap hr anchor searchreplace wordcount visualblocks visualchars insertdatetime nonbreaking save directionality paste textcolor colorpicker textpattern placeholder';
        if (typeof (MarvinJsEditor) !== 'undefined') plugins += ' marvinjsplugin';

        if (textAreaObject.data('objectType') === 'step'
          || textAreaObject.data('objectType') === 'result_text') {
          document.location.hash = textAreaObject.data('objectType') + '_' + textAreaObject.data('objectId');
        }

        tinyMCE.init({
          cache_suffix: '?v=4.9.3', // This suffix should be changed any time library is updated
          selector: selector,
          convert_urls: false,
          menubar: 'file edit view insert format',
          toolbar: 'undo redo restoredraft | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link | forecolor backcolor | customimageuploader marvinjsplugin | codesample',
          plugins: plugins,
          autoresize_bottom_margin: 20,
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
          autosave_restore_when_empty: false,
          autosave_interval: '1s',
          autosave_retention: '1440m',
          removed_menuitems: 'newdocument',
          object_resizing: true,
          elementpath: false,
          forced_root_block: 'div',
          force_p_newlines: false,
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
            var editorForm = $(editor.getContainer()).closest('form');
            var menuBar = editorForm.find('.mce-menubar.mce-toolbar.mce-first .mce-flow-layout');
            var editorToolbar = editorForm.find('.mce-top-part');

            var editorToolbaroffset;

            $('.tinymce-placeholder').css('height', $(editor.editorContainer).height() + 'px');
            setTimeout(() => {
              $(editor.editorContainer).addClass('show');
              $('.tinymce-placeholder').remove();
            }, 400);

            // Init saved status label
            if (editor.getContent() !== '') {
              editorForm.find('.tinymce-status-badge').removeClass('hidden');
            }

            if ($('.navbar-secondary').length) {
              editorToolbaroffset = $('.navbar-secondary').position().top + $('.navbar-secondary').height();
            } else if ($('#main-nav').length) {
              editorToolbaroffset = $('#main-nav').height();
            } else {
              editorToolbaroffset = 0;
            }

            if (GLOBAL_CONSTANTS.IS_SAFARI) {
              editorToolbar.css('position', '-webkit-sticky');
            } else {
              editorToolbar.css('position', 'sticky');
            }
            editorToolbar.css('top', editorToolbaroffset + 'px').css('z-index', '100');

            // Init image toolbar
            initImageToolBar(editor);

            // Update scroll position after exit
            function updateScrollPosition() {
              if (editorForm.offset().top < $(window).scrollTop()) {
                $(window).scrollTop(editorForm.offset().top - 150);
              }
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
                updateScrollPosition();
              });

            // After save action
            editorForm
              .on('ajax:success', function(ev, data) {
                editor.save();
                editor.setProgressState(0);
                editorForm.find('.tinymce-status-badge').removeClass('hidden');
                editor.remove();
                editorForm.find('.tinymce-view').html(data.html).removeClass('hidden');
                editor.plugins.autosave.removeDraft();
                if (onSaveCallback) { onSaveCallback(); }
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
                editorForm.find('.tinymce-status-badge').addClass('hidden');
                editorForm.find('.tinymce-view').removeClass('hidden');
                editor.remove();
                updateScrollPosition();
              })
              .removeClass('hidden');

            // Set cursor to the end of the content
            if (editor.settings.id !== 'step_description_textarea') {
              editor.focus();
            }
            editor.selection.select(editor.getBody(), true);
            editor.selection.collapse(false);

            SmartAnnotation.init($(editor.contentDocument.activeElement));
            SmartAnnotation.preventPropagation('.atwho-user-popover');
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

            editor.on('Dirty', function() {
              makeItDirty(editor);
            });

            editor.on('remove', function() {
              var menuBar = $(editor.getContainer()).find('.mce-menubar.mce-toolbar.mce-first .mce-flow-layout');
              menuBar.find('.tinymce-save-button').remove();
              menuBar.find('.tinymce-cancel-button').remove();
            });

            editor.on('blur', function(e) {
              if ($('.atwho-view:visible').length || $('#MarvinJsModal:visible').length) return false;
              setTimeout(() => {
                if (editor.isNotDirty === false) {
                  $(editor.container).find('.tinymce-save-button').click();
                } else {
                  $(editor.container).find('.tinymce-cancel-button').click();
                }
              }, 0);
              return true;
            });

            editor.on('init', function(e) {
              restoreDraftNotification(selector, editor);
            });
          },
          codesample_content_css: $(selector).data('highlightjs-path')
        });
      }
    },
    destroyAll: function() {
      _.each(tinyMCE.editors, function(editor) {
        if (editor) {
          editor.remove();
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
    updateImages(editor) {
      var images;
      var iframe = $('#' + editor.id).prev().find('.mce-edit-area iframe').contents();
      images = $.map($('img', iframe), e => {
        return e.dataset.mceToken;
      });
      $('#' + editor.id).next()[0].value = JSON.stringify(images);
      return JSON.stringify(images);
    },
    makeItDirty: function(editor) {
      makeItDirty(editor);
    },
    highlight: initHighlightjs
  });
}());

$(document).on('turbolinks:before-visit', function(e) {
  _.each(tinyMCE.editors, function(editor) {
    if (editor.isNotDirty === false) {
      if (confirm(I18n.t('tiny_mce.leaving_warning'))) {
        return false;
      }
      e.preventDefault();
      return false;
    }
    return false;
  });
});
