/* global tinymce */

tinymce.PluginManager.add('placeholder', function(editor) {
  var Label = function() {
    var editorForm = $(editor.getContainer()).closest('form');
    var editorToolbar = editorForm.find('.mce-top-part');
    var placeholderText = editor.getElement().getAttribute('placeholder') || editor.settings.placeholder;
    var placeholderAttrs = {
      style: `
        position: 'absolute',
        top: (editorToolbar.height()) + 'px',
        left: 0,
        color: '#888',
        padding: '1%',
        width: 'calc(100% - 50px)',
        overflow: 'hidden',
        'white-space': 'pre-wrap'
      `
    };
    var contentAreaContainer = editor.getContentAreaContainer();


    // Create label el
    this.el = tinymce.DOM.add(contentAreaContainer, editor.settings.placeholder_tag || 'label', placeholderAttrs, placeholderText);
  };


  editor.on('init', function() {
    var label = new Label();

    // Correct top css property due to notification bar
    function calculatePlaceholderPosition() {
      var editorForm = $(editor.getContainer()).closest('form');
      var editorToolbar = editorForm.find('.mce-top-part');

      var restoreDraftNotification = $(editorForm).find('.restore-draft-notification');
      var restoreDraftHeight = restoreDraftNotification.context ? restoreDraftNotification.height() : 0;
      var newTop = $(editorToolbar).height() + restoreDraftHeight;
      $(label.el).css('top', newTop + 'px');
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

    $(label.el).click(function() {
      editor.focus();
    });

    checkPlaceholder();

    editor.on('focus blur change setContent keyup', checkPlaceholder);
    editor.on('keydown', onKeydown);
  });

  Label.prototype.hide = function() {
    tinymce.DOM.setStyle(this.el, 'display', 'none');
  };

  Label.prototype.show = function() {
    tinymce.DOM.setStyle(this.el, 'display', '');
  };
});
