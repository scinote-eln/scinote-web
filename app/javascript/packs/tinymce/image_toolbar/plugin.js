/* global tinymce MarvinJsEditor */
tinymce.PluginManager.add('custom_image_toolbar', (editor) => {
  editor.ui.registry.addButton('image_download', {
    icon: 'upload',
    onAction: () => {
      const editorIframe = $(`#${editor.id}`).next().find('.tox-edit-area iframe');
      const image = editorIframe.contents().find('img[data-mce-selected="1"]');

      window.open(`/tiny_mce_assets/${image.data('mce-token')}/download`, '_blank');
    }
  });

  editor.ui.registry.addButton('marvinjs_edit', {
    icon: 'edit-block',
    onAction: () => {
      const editorIframe = $(`#${editor.id}`).next().find('.tox-edit-area iframe');
      const image = editorIframe.contents().find('img[data-mce-selected="1"]');
      MarvinJsEditor.open({
        mode: 'edit-tinymce',
        marvinUrl: `/tiny_mce_assets/${image[0].dataset.mceToken}/marvinjs`,
        editor,
        image
      });
    }
  });

  function isImage(elem) {
    return editor.dom.is(elem, 'img') && elem.dataset.mceToken;
  }
  function isMarvinJs(elem) {
    return elem.dataset.sourceType === 'marvinjs';
  }

  editor.ui.registry.addContextToolbar('marvinJsToolbar', {
    predicate: (node) => isMarvinJs(node),
    items: 'marvinjs_edit',
    position: 'node',
    scope: 'node'
  });

  editor.ui.registry.addContextToolbar('ImageToolbar', {
    predicate: (node) => isImage(node),
    items: 'image_download',
    position: 'node',
    scope: 'node'
  });
});
