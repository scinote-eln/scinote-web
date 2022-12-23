/* global tinymce */

tinymce.PluginManager.add('placeholder', (editor) => {
  const Label = () => {
    // const editorForm = $(editor.getContainer()).closest('form');
    // const editorToolbar = editorForm.find('.tox-editor-header');
    const placeholderText = editor.getElement().getAttribute('placeholder');
    const placeholderAttrs = {
      style: `
        position: 'absolute',
        top: '0px',
        left: '0px',
        color: '#888',
        padding: '1%',
        width: 'calc(100% - 50px)',
        overflow: 'hidden',
        'white-space': 'pre-wrap'
      `
    };
    const contentAreaContainer = editor.getContentAreaContainer();


    // Create label el
    this.el = editor.dom.add(contentAreaContainer, 'label', placeholderAttrs, placeholderText);
  };


  editor.on('init', () => {
    const label = new Label();

    // Correct top css property due to notification bar
    function calculatePlaceholderPosition() {
      const editorForm = $(editor.getContainer()).closest('form');
      const editorToolbar = editorForm.find('.mce-top-part');

      const restoreDraftNotification = $(editorForm).find('.restore-draft-notification');
      const restoreDraftHeight = restoreDraftNotification.context ? restoreDraftNotification.height() : 0;
      const newTop = $(editorToolbar).height() + restoreDraftHeight;
      $(label.el).css('top', `${newTop}px`);
    }

    function checkPlaceholder() {
      // Show/hide depending on the content
      if (editor.getContent() === '') {
        label.show();
      } else {
        label.hide();
      }

      calculatePlaceholderPosition();
    }

    function onKeydown() {
      label.hide();
    }

    $(label.el).click(() => {
      editor.focus();
    });

    checkPlaceholder();

    editor.on('focus blur change setContent keyup', checkPlaceholder);
    editor.on('keydown mousedown', onKeydown);
  });

  Label.prototype.hide = () => {
    editor.dom.setStyle(this.el, 'display', 'none');
  };

  Label.prototype.show = () => {
    editor.dom.setStyle(this.el, 'display', '');
  };
});
