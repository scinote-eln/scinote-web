/* global dropdownSelector TinyMCE */
var ProtocolRepositoryHeader = (function() {
  function initEditKeywords() {
    dropdownSelector.init('#keyword-input-field', {
      inputTagMode: true,
      onChange: function() {
        $.ajax({
          url: $('#keyword-input-field').data('update-url'),
          type: 'PATCH',
          dataType: 'json',
          data: { keywords: dropdownSelector.getValues('#keyword-input-field') },
          success: function() {
            dropdownSelector.highlightSuccess('#keyword-input-field');
          },
          error: function() {
            dropdownSelector.highlightError('#keyword-input-field');
          }
        });
      }
    });
  }

  function initEditDescription() {
    var viewObject = $('#protocol_description_view');
    viewObject.on('click', function(e) {
      if ($(e.target).hasClass('record-info-link')) return;
      TinyMCE.init('#protocol_description_textarea');
    }).on('click', 'a', function(e) {
      if ($(this).hasClass('record-info-link')) return;
      e.stopPropagation();
    });
  }

  return {
    init: () => {
      if ($('.protocol-repository-header').length > 0) {
        initEditKeywords();
        initEditDescription();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  ProtocolRepositoryHeader.init();
});
