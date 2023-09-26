/* global windowScrollEvents HelperModule I18n PdfPreview */
$(document).on('click', '.asset-context-menu .change-preview-type', function(e) {
  var viewModeBtn = $(this);
  var viewMode = viewModeBtn.data('preview-type');
  var toggleUrl = viewModeBtn.closest('.dropdown-menu').data('toggle-view-url');
  var assetId = viewModeBtn.closest('.dropdown-menu').data('asset-id');
  e.preventDefault();
  e.stopPropagation();
  $.ajax({
    url: toggleUrl,
    type: 'PATCH',
    dataType: 'json',
    data: { asset: { view_mode: viewMode } },
    success: function(data) {
      viewModeBtn.closest('.dropdown-menu').find('.change-preview-type').removeClass('selected');
      viewModeBtn.addClass('selected');
      $(`.asset[data-asset-id=${assetId}]`).replaceWith(data.html);
      PdfPreview.initCanvas();
    }
  });
});

$(document).on('click', '.asset .delete-asset', function(e) {
  var asset = $(this).closest('.asset');
  var fileName = $(this).data('file-name');
  e.preventDefault();
  e.stopPropagation();
  $.ajax({
    url: $(this).attr('href'),
    type: 'DELETE',
    dataType: 'json',
    beforeSend: function(element, ajaxSettings) {
      var deleteModal = $('.modal-file-delete');
      var ajax = ajaxSettings;
      ajax.beforeSend = null;
      deleteModal.find('.asset-confirmation-description')
        .html(I18n.t('assets.delete_file_modal.description_1_html', { file_name: fileName }));
      deleteModal.find('.confirm-button').attr('disabled', false);
      deleteModal.modal('show');
      deleteModal.off('click', '.confirm-button').one('click', '.confirm-button', { ajax: ajax }, function(button) {
        $(this).attr('disabled', true);
        $.ajax(button.data.ajax);
      });
      return false;
    },
    success: function(result) {
      asset.remove();
      HelperModule.flashAlertMsg(result.flash, 'success');
    },
    error: function() {
      HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
    }
  });
});

$(document).on('turbolinks:before-visit', (e) => {
  if ($('.uploading-attachment-container:not(.error)').length) {
    if (confirm(I18n.t('attachments.new.leaving_warning'))) {
      return true;
    }
    e.preventDefault();
    return false;
  }
  return true;
});

var InlineAttachments = (function() {
  function elementVisible(element) {
    var elementRect = element.getBoundingClientRect();
    var elementHeight = $(element).height();
    return elementRect.top + (elementHeight / 2) >= 0
           && elementRect.bottom <= (window.innerHeight || document.documentElement.clientHeight) + (elementHeight / 2);
  }

  function showElement(element) {
    setTimeout(() => {
      var iframeUrl = $(element).find('.iframe-placeholder').data('iframe-url');
      if (elementVisible(element) && iframeUrl) {
        $(element).find('.iframe-placeholder')
          .replaceWith(`<iframe class="active-iframe-preview" src="${iframeUrl}"></iframe>`);
        $(element).addClass('active').attr('data-created-at', new Date().getTime());
      }
    }, 500);
  }

  function hideElement(element) {
    var iframeUrl = $(element).find('.active-iframe-preview').attr('src');
    if (!elementVisible(element) && iframeUrl) {
      $(element).find('iframe')
        .replaceWith(`<div class="iframe-placeholder" data-iframe-url="${iframeUrl}"></div>`);
      $(element).removeClass('active').attr('data-created-at', null);
      return true;
    }
    return false;
  }

  function checkForAttachmentsState() {
    $.each($('.inline-attachment-container'), function(i, element) {
      showElement(element);
    });
    if ($('.active-iframe-preview').length > 5) {
      let sortedIframes = $('.inline-attachment-container.active').sort(function(a, b) {
        return +a.dataset.createdAt - +b.dataset.createdAt;
      });
      $.each(sortedIframes, function(i, element) {
        if (hideElement(element)) return false;
      });
    }
  }

  function initReloadButtons() {
    $(document).on('ajax:success', '.asset .reload-asset', function(e, data) {
      $(this).closest('.asset').replaceWith(data.html);
    });
  }

  return {
    init: () => {
      windowScrollEvents.InlineAttachments = InlineAttachments.scrollEvent;
    },
    initReloadButtons: () => {
      initReloadButtons();
    },
    scrollEvent: () => {
      checkForAttachmentsState();
    }
  };
})();

$(document).on('turbolinks:load', function() {
  InlineAttachments.init();
  InlineAttachments.scrollEvent();
});
InlineAttachments.initReloadButtons();
