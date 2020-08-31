/* global tinymce MarvinJsEditor */
tinymce.PluginManager.add('custom_image_toolbar', function(editor) {
  editor.addButton('image_download', {
    icon: 'download',
    onclick: function() {
      var editorIframe = $('#' + editor.id).prev().find('.mce-edit-area iframe');
      var image = editorIframe.contents().find('img[data-mce-selected="1"]');
      window.open('/tiny_mce_assets/' + image.data('mceToken') + '/download', '_blank');
    }
  });

  editor.addButton('marvinjs_edit', {
    icon: 'pencil',
    onclick: function() {
      var editorIframe = $('#' + editor.id).prev().find('.mce-edit-area iframe');
      var image = editorIframe.contents().find('img[data-mce-selected="1"]');
      MarvinJsEditor.open({
        mode: 'edit-tinymce',
        marvinUrl: '/tiny_mce_assets/' + image[0].dataset.mceToken + '/marvinjs',
        editor: editor,
        image: image
      });
    }
  });

  function isImage(elem) {
    return editor.dom.is(elem, 'img') && elem.dataset.mceToken;
  }
  function isMarvinJs(elem) {
    return elem.dataset.sourceType === 'marvinjs';
  }

  editor.addContextToolbar(isImage, 'image_download');
  editor.addContextToolbar(isMarvinJs, 'image_download marvinjs_edit');
});
