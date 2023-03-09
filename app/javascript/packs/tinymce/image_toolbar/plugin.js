/* global I18n tinymce MarvinJsEditor */
tinymce.PluginManager.add('custom_image_toolbar', (editor) => {

  editor.ui.registry.addIcon(
    'download',
    `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" stroke="none" stroke-linecap="round" stroke-linejoin="round" fill-rule="nonzero" focusable="false">
      <path d="M26.835 17.1193c-.4295-.0002-.8415.1703-1.1452.474a1.618 1.618 0 0 0-.474 1.1453v4.8579H5.7843v-4.8579c0-.8943-.725-1.6193-1.6193-1.6193s-1.6193.725-1.6193 1.6193v6.4771c-.0002.4296.1703.8416.474 1.1453a1.618 1.618 0 0 0 1.1453.474h22.67c.4296.0003.8416-.1702 1.1453-.474s.4743-.7157.474-1.1453v-6.4771a1.618 1.618 0 0 0-.474-1.1453c-.3037-.3037-.7157-.4742-1.1453-.474zm-12.4799 2.7642a1.619 1.619 0 0 0 2.2898 0l4.8579-4.8579c.6293-.6328.6279-1.6555-.0032-2.2866s-1.6538-.6325-2.2866-.0032l-2.0937 2.0937V5.7843c0-.8943-.725-1.6193-1.6193-1.6193s-1.6193.725-1.6193 1.6193v9.0452l-2.0937-2.0937c-.6328-.6293-1.6555-.6278-2.2866.0032s-.6325 1.6538-.0032 2.2866z"></path>
    </svg>`
  );

  editor.ui.registry.addButton('image_download', {
    icon: 'download',
    tooltip: I18n.t('general.download'),
    onAction: () => {
      const editorIframe = $(`#${editor.id}`).next().find('.tox-edit-area iframe');
      const image = editorIframe.contents().find('img[data-mce-selected="1"]');

      window.open(`/tiny_mce_assets/${image.data('mce-token')}/download`, '_blank');
    }
  });

  editor.ui.registry.addButton('marvinjs_edit', {
    icon: 'edit-block',
    tooltip: I18n.t('general.edit'),
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

  // This method removes image edit button groups if the selected image is a MarvinJS image
  // Since there is no appropriate TinyMCE event to catch the render of the toolbar
  // we need to rely on a MutationObserver, which will watch the TinyMCE context toolbar element,
  // and then remove the two image editing groups.
  function removeImageEditButtons() {
    const tinyMceAuxNode = document.getElementsByClassName('tox-tinymce-aux')[0];
    const tinyMceAuxNodeObserver = new MutationObserver(() => {
      let toxPop = document.getElementsByClassName('tox-pop')[0];
      if (!toxPop) return;

      let toolbarGroups = toxPop.getElementsByClassName('tox-toolbar__group');
      if (toolbarGroups[3]) {
        toolbarGroups[3].classList.add('hidden');
      }
    });

    tinyMceAuxNodeObserver.observe(tinyMceAuxNode, { attributes: false, childList: true, subtree: false });

    // We can stop observing once the toolbar was loaded and changed.
    setTimeout(() => { tinyMceAuxNodeObserver.disconnect() }, 100);

    return true;
  }

  editor.ui.registry.addContextToolbar('marvinJsToolbar', {
    predicate: (node) => isMarvinJs(node) && removeImageEditButtons(),
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
