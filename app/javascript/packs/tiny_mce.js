/* global I18n GLOBAL_CONSTANTS HelperModule SmartAnnotation TinyMCE */

import tinyMCE from 'tinymce/tinymce';
import 'tinymce/models/dom';
import 'tinymce/icons/default';
import 'tinymce/themes/silver';

import 'tinymce/plugins/table';
import 'tinymce/plugins/autosave';
import 'tinymce/plugins/autoresize';
import 'tinymce/plugins/link';
import 'tinymce/plugins/advlist';
import 'tinymce/plugins/codesample';
import 'tinymce/plugins/code';
import 'tinymce/plugins/autolink';
import 'tinymce/plugins/lists';
import 'tinymce/plugins/image';
import 'tinymce/plugins/charmap';
import 'tinymce/plugins/anchor';
import 'tinymce/plugins/searchreplace';
import 'tinymce/plugins/wordcount';
import 'tinymce/plugins/visualblocks';
import 'tinymce/plugins/visualchars';
import 'tinymce/plugins/insertdatetime';
import 'tinymce/plugins/nonbreaking';
import 'tinymce/plugins/save';
import 'tinymce/plugins/help';
import 'tinymce/plugins/help/js/i18n/keynav/en';
import 'tinymce/plugins/quickbars';
import 'tinymce/plugins/directionality';
import './tinymce/custom_image_uploader/plugin';
import './tinymce/marvinjs/plugin';
import './tinymce/image_toolbar/plugin';

// Content styles, including inline UI like fake cursors
// All the above CSS files are loaded on to the page but these two must
// be loaded into the editor iframe so they are loaded as strings and passed
// to the init function.
import 'raw-loader';
import contentCss from '!!raw-loader!tinymce/skins/content/default/content.min.css';
import contentUiCss from '!!raw-loader!tinymce/skins/ui/tinymce-5/content.min.css';

const contentPStyle = `p { margin: 0; padding: 0;}`;
const contentBodyStyle = `body { font-family: "SN Inter", "Open Sans", Arial, Helvetica, sans-serif }`;
const contentStyle = [contentCss, contentUiCss, contentBodyStyle, contentPStyle].map((s) => s.toString()).join('\n');

// Optional pre-initialization method
if (typeof(window.preTinyMceInit) === 'function') {
  window.preTinyMceInit();
}

window.TinyMCE = (() => {
  function makeItDirty(editor) {
    const editorForm = $(editor.getContainer()).closest('form');
    editorForm.find('.tinymce-status-badge').addClass('hidden');
    $(editor.getContainer()).find('.tinymce-save-button').removeClass('hidden');
  }

  // Get LocalStorage auto save path
  function getAutoSavePrefix(editor) {
    let prefix = editor.getParam('autosave_prefix', 'tinymce-autosave-{path}{query}{hash}-{id}-');

    prefix = prefix.replace(/\{path\}/g, document.location.pathname);
    prefix = prefix.replace(/\{query\}/g, document.location.search);
    prefix = prefix.replace(/\{hash\}/g, document.location.hash);
    prefix = prefix.replace(/\{id\}/g, editor.id);

    return prefix;
  }

  // Handles autosave notification if draft is available in the local storage
  function restoreDraftNotification(selector, editor) {
    const prefix = getAutoSavePrefix(editor);
    const lastDraftTime = parseInt(tinyMCE.util.LocalStorage.getItem(`${prefix}time`), 10);
    const lastUpdated = $(selector).data('last-updated');
    let notificationBar;
    const restoreBtn = $('<button class="btn restore-draft-btn">Restore Draft</button>');
    const cancelBtn = $('<span class="sn-icon sn-icon-close"></span>');

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

      // Prevents save on blur if clicking draft notification
      $('.restore-draft-notification').on('mousedown', () => {
        editor.isBlurTempDisabled = true;
        setTimeout(() => {
          editor.isBlurTempDisabled = false;
        }, 500);
      });

      $(restoreBtn).click(() => {
        editor.plugins.autosave.restoreDraft();
        makeItDirty(editor);
        notificationBar.remove();
      });

      $(cancelBtn).click(() => {
        notificationBar.remove();
      });
    }

    setTimeout(() => { tinyMCE.activeEditor.execCommand('mceAutoResize') }, 500);
  }

  function initCssOverrides(editor) {
    const editorIframe = $(`#${editor.id}`).next().find('.tox-edit-area iframe');
    const primaryColor = '#104da9';
    editorIframe.contents().find('head').append(`<style type="text/css">
        img::-moz-selection{background:0 0}
        img::selection{background:0 0}
        .mce-content-body img[data-mce-selected]{outline:2px solid ${primaryColor}}
        .mce-content-body div.mce-resizehandle{background:transparent;border-color:transparent;box-sizing:border-box;height:10px;width:10px; position:absolute}
        .mce-content-body div.mce-resizehandle:hover{background:transparent}
        .mce-content-body div#mceResizeHandlenw{border-left: 2px solid ${primaryColor}; border-top: 2px solid ${primaryColor}}
        .mce-content-body div#mceResizeHandlene{border-right: 2px solid ${primaryColor}; border-top: 2px solid ${primaryColor}}
        .mce-content-body div#mceResizeHandlesw{border-left: 2px solid ${primaryColor}; border-bottom: 2px solid ${primaryColor}}
        .mce-content-body div#mceResizeHandlese{border-right: 2px solid ${primaryColor}; border-bottom: 2px solid ${primaryColor}}
        h1 {font-size: 24px !important }
        h2 {font-size: 18px !important }
        h3 {font-size: 16px !important }
      </style>`);
    editorIframe.contents().find('head').append($('#font-css-pack').clone());
  }

  function draftLocation() {
    return `tinymce-drafts-${document.location.pathname}`;
  }

  function removeDraft(editor, textAreaObject) {
    const location = draftLocation();
    const storedDrafts = JSON.parse(sessionStorage.getItem(location) || '[]');
    const draftId = storedDrafts.indexOf(textAreaObject.data('tinymce-object'));
    if (draftId > -1) {
      storedDrafts.splice(draftId, 1);
    }

    if (storedDrafts.length) {
      sessionStorage.setItem(location, JSON.stringify(storedDrafts));
    } else {
      sessionStorage.removeItem(location);
    }
  }

  // Update scroll position after exit
  function updateScrollPosition(editorForm) {
    if (editorForm.offset().top < $(window).scrollTop()) {
      $(window).scrollTop(editorForm.offset().top - 150);
    }
  }

  function saveAction(editor) {
    const editorForm = $(editor.getContainer()).closest('form');
    editorForm.clearFormErrors();
    editor.setProgressState(1);
    editor.save();
    editorForm.submit();
    updateScrollPosition(editorForm);
  }

  // returns a public API for TinyMCE editor
  return {
    init: (selector, options = {}) => {
      const textAreaObject = $(selector);
      let editorToolbaroffset = 0;

      if (typeof tinyMCE !== 'undefined') {
        // Hide element containing HTML view of RTE field
        const tinyMceContainer = $(selector).closest('form').find('.tinymce-view');
        const editorForm = $(selector).closest('form');
        const tinyMceInitSize = tinyMceContainer.height();

        editorForm.parent().height(tinyMceInitSize);
        tinyMceContainer.addClass('hidden');

        const plugins = `
          image table autosave autoresize link advlist codesample code autolink lists
          charmap anchor searchreplace wordcount visualblocks visualchars
          insertdatetime nonbreaking save directionality customimageuploader
          marvinjs custom_image_toolbar help quickbars ${window.extraTinyMcePlugins ? window.extraTinyMcePlugins : ''}
        `;
        // if (typeof (MarvinJsEditor) !== 'undefined') plugins += ' marvinjsplugin';

        if (textAreaObject.data('objectType') === 'step'
          || textAreaObject.data('objectType') === 'result_text') {
          document.location.hash = `${textAreaObject.data('objectType')}_${textAreaObject.data('objectId')}`;
        }

        editorToolbaroffset = 0;

        $.each($('.sticky-header-element, .sticky-header'), (_index, element) => {
          editorToolbaroffset += $(element).outerHeight();
        });

        return tinyMCE.init({
          cache_suffix: '?v=6.5.1-19', // This suffix should be changed any time library is updated
          selector,
          skin: false,
          editimage_fetch_image: img => new Promise((resolve) => {
            // Appending a timestamp to an image URL bypasses Chrome’s cache, resolving occasional CORS errors
            fetch(img.src + '?t=' + new Date().getTime())
              .then(response => response.blob())
              .then(blob => resolve(blob));
          }),
          content_css: false,
          content_style: contentStyle,
          convert_urls: false,
          promotion: false,
          menu: {
            insert: { title: 'Insert', items: 'link codesample inserttable | charmap hr | nonbreaking anchor | insertdatetime customimageuploader marvinjs' },
          },
          block_formats: 'Paragraph=p; Header 1=h1; Header 2=h2; Header 3=h3; Preformatted=pre',
          menubar: 'file edit view insert format table',
          toolbar: window.customTinyMceToolbar || 'undo redo restoredraft | insert | styleselect | bold italic | forecolor backcolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | table | customimageuploader | marvinjs link codesample | help',
          plugins,
          contextmenu: '',
          autoresize_bottom_margin: 20,
          placeholder: options.placeholder,
          toolbar_sticky: true,
          toolbar_sticky_offset: editorToolbaroffset,
          codesample_global_prismjs: true,
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
          quickbars_insert_toolbar: false,
          toolbar_mode: 'sliding',
          color_default_background: 'yellow',
          link_default_target: 'external',
          mobile: {
            menubar: 'file edit view insert format table'
          },
          link_target_list: [
            { title: 'New page', value: 'external' },
            { title: 'Same page', value: '_self' }
          ],
          style_formats: [
            {
              title: 'Headers',
              items: [
                { title: 'Header 1', format: 'h1' },
                { title: 'Header 2', format: 'h2' },
                { title: 'Header 3', format: 'h3' }
              ]
            },
            {
              title: 'Inline',
              items: [
                { title: 'Bold', icon: 'bold', format: 'bold' },
                { title: 'Italic', icon: 'italic', format: 'italic' },
                { title: 'Underline', icon: 'underline', format: 'underline' },
                { title: 'Strikethrough', icon: 'strike-through', format: 'strikethrough' },
                { title: 'Superscript', icon: 'superscript', format: 'superscript' },
                { title: 'Subscript', icon: 'subscript', format: 'subscript' },
                { title: 'Code', icon: 'sourcecode', format: 'code' }
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
                { title: 'Left', icon: 'align-left', format: 'alignleft' },
                { title: 'Center', icon: 'align-center', format: 'aligncenter' },
                { title: 'Right', icon: 'align-right', format: 'alignright' },
                { title: 'Justify', icon: 'align-justify', format: 'alignjustify' }
              ]
            }
          ],
          init_instance_callback: (editor) => {

            const editorContainer = $(editor.getContainer());
            const editorForm = editorContainer.closest('form');
            const menuBar = editorForm.find('.tox-menubar');

            editorContainer.addClass('tox-tinymce--loaded');
            const event = new CustomEvent('tinyMCEOpened', {
              detail: {
                target: editorForm.parent(),
              }
            });
            window.dispatchEvent(event);
            editorForm.parent().css('height', '');

            // Init saved status label
            if (editor.getContent() !== '') {
              editorForm.find('.tinymce-status-badge').removeClass('hidden');
            }

            // Remove transition class
            $('.tox-editor-header').removeClass('tox-editor-dock-fadeout');

            // Init image toolbar
            initCssOverrides(editor);

            // Init save/cancel button wrapper
            $('<div class="tinymce-save-controls"></div>').appendTo(menuBar);

            // Init Save button
            editorForm
              .find('.tinymce-save-button')
              .clone()
              .appendTo(menuBar.find('.tinymce-save-controls'))
              .on('click', (event) => {
                event.preventDefault();
                saveAction(editor);
                SmartAnnotation.closePopup();
              });

            // After save action
            editorForm
              .on('ajax:success', (_ev, data) => {
                editor.save();
                editor.setProgressState(0);
                editorForm.find('.tinymce-status-badge').removeClass('hidden');
                editor.remove();
                editorForm.find('.tinymce-view').html(data.html).removeClass('hidden');
                TinyMCE.wrapTables(editorForm.find('.tinymce-view'));
                editor.plugins.autosave.removeDraft();
                removeDraft(editor, textAreaObject);
                if (options.onSaveCallback) { options.onSaveCallback(data); }
              }).on('ajax:error', (_ev, data) => {
                const model = editor.getElement().dataset.objectType;
                let form = $(editor.getElement().closest('.form-group'));
                form.renderFormErrors(model, data.responseJSON);

                // to show bottom of the tinyMce editor instead at the top
                form.find('.help-block').insertAfter(form.children().last());
                editor.setProgressState(0);
                if (data.status === 403) {
                  HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
                } else if (data.status === 422) {
                  HelperModule.flashAlertMsg(data.responseJSON ? Object.values(data.responseJSON).join(', ') : I18n.t('errors.general'), 'danger');
                }
              });

            // Init Cancel button
            editorForm
              .find('.tinymce-cancel-button')
              .clone()
              .prependTo(menuBar.find('.tinymce-save-controls'))
              .on('click', (event) => {
                $(editorForm).find('.form-group').removeClass('has-error');
                $(editorForm).find('.help-block').remove();

                event.preventDefault();
                if (editor.isDirty()) {
                  editor.setContent($(selector).val());
                }
                editorForm.find('.tinymce-status-badge').addClass('hidden');
                editorForm.find('.tinymce-view').removeClass('hidden');
                editor.remove();

                updateScrollPosition(editorForm);
                if (options.onSaveCallback) { options.onSaveCallback($(selector).val()); }

                SmartAnnotation.closePopup();
              })
              .removeClass('hidden');

            editor.selection.select(editor.getBody(), true);
            editor.selection.collapse(false);

            SmartAnnotation.init($(editor.contentDocument.activeElement), false, options.assignableMyModuleId);
            SmartAnnotation.preventPropagation('.atwho-user-popover');

            if (options.afterInitCallback) { options.afterInitCallback(); }
          },
          setup: (editor) => {
            editor.isBlurTempDisabled = false;

            editor.on('keydown', (e) => {
              if (e.key === 'Enter' && $(editor.contentDocument.activeElement).atwho('isSelecting')) {
                return false;
              }
              return true;
            });

            editor.on('Dirty', () => {
              makeItDirty(editor);
            });

            editor.on('StoreDraft', () => {
              const location = draftLocation();
              const storedDrafts = JSON.parse(sessionStorage.getItem(location) || '[]');
              const draftName = textAreaObject.data('tinymce-object');
              if (storedDrafts.includes(draftName) || !draftName) return;
              storedDrafts.push(draftName);
              sessionStorage.setItem(location, JSON.stringify(storedDrafts));
            });

            editor.on('remove', () => {
              const menuBar = $(editor.getContainer()).find('.tox-menubar');
              menuBar.find('.tinymce-save-button').remove();
              menuBar.find('.tinymce-cancel-button').remove();
            });

            editor.on('blur', () => {
              if (editor.isBlurTempDisabled || editor.blurDisabled) return false;

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

            editor.on('init', () => {
              restoreDraftNotification(selector, editor);
            });

            editor.on('BeforeSetContent GetContent', function(e) {
              if (e.content && e.content.includes('target="external"')) {
                const div = document.createElement('div');
                div.innerHTML = e.content;
                const links = div.querySelectorAll('a[target="external"]');
                links.forEach(link => {
                  link.removeAttribute('target');
                  link.setAttribute('rel', 'external');
                });
                e.content = div.innerHTML;
              }
            });
          },
          save_onsavecallback: (editor) => { saveAction(editor); }
        });
      }

      return null;
    },
    destroyAll: () => {
      if (tinyMCE.activeEditor) {
        tinyMCE.activeEditor.remove();
      }
    },
    refresh: () => {
      this.destroyAll();
      this.init();
    },
    getContent: () => tinyMCE.activeEditor && tinyMCE.activeEditor.getContent(),
    updateImages: (editor) => {
      const iframe = $(`#${editor.id}`).next().find('.tox-edit-area iframe').contents();
      const images = $.map($('img', iframe), e => e.dataset.mceToken);
      $(`#${editor.id}`).parent().find('input.tiny-mce-images').val(JSON.stringify(images));
      return JSON.stringify(images);
    },
    makeItDirty: (editor) => {
      makeItDirty(editor);
    },
    wrapTables: (container) => {
      container.find('table').toArray().forEach((table) => {
        if ($(table).parent().hasClass('table-wrapper')) return;

        $(table).css('float', 'none').wrapAll(`
          <div class="table-wrapper" style="overflow: auto; width: ${container.width()}px"></div>
        `);
      });
    }
  };
})();

$(document).on('turbolinks:before-visit', (e) => {
  const editor = tinyMCE.activeEditor;

  if (editor === null) return true;

  if (editor.isDirty()) {
    // eslint-disable-next-line no-alert
    if (confirm(I18n.t('tiny_mce.leaving_warning'))) {
      $('.atwho-container').remove();
      tinyMCE.activeEditor.remove();
      return true;
    }
    e.preventDefault();
    return false;
  }
  return true;
});
