/* eslint no-underscore-dangle: ["error", { "allowAfterThis": true }]*/
/* eslint no-use-before-define: ["error", { "functions": false }]*/
/* eslint-disable no-underscore-dangle */
/* global Uint8Array fabric tui animateSpinner Assets ActiveStoragePreviews
   PerfectScrollbar MarvinJsEditor refreshProtocolStatusBar  */


var FilePreviewModal = (function() {
  'use strict';

  //var readOnly = false;

  function initPreviewModal(options = {}) {
    $(document).on('click', '.file-preview-link', function(e) {
      e.preventDefault();
      $.get($(this).data('preview-url'), function(result) {
        $('#filePreviewModal .modal-content').html(result.html);
        $('#filePreviewModal').modal('show');
      })
    })
    //var name;
    //var url;
    //var downloadUrl;
    //readOnly = options.readOnly;

    //return false;
    //
    //$('.file-preview-link').off('click');
    //$('.file-preview-link').click(function(e) {
    //  if ($(e.target.offsetParent).hasClass('change-preview-type')) return;
    //  e.preventDefault();
    //  name = $(this).find('.attachment-label').text();
    //  url = $(this).data('preview-url');
    //  downloadUrl = $(this).attr('href');
    //  openPreviewModal(name, url, downloadUrl);
    //  return true;
    //});
    //
    //$('#filePreviewModal').find('.preview-close').click(function() {
    //  $('#filePreviewModal').find('.file-preview-container').html('');
    //  $('#filePreviewModal').modal('hide');
    //  if (typeof refreshProtocolStatusBar === 'function') refreshProtocolStatusBar();
    //});
  }

  // Adding rotation icon


  function openPreviewModal(name, url, downloadUrl) {

    /*
    var modal = $('#filePreviewModal');
    updateFabricControls();
    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        var link = modal.find('.file-download-link');
        clearPrevieModal();
        if (Object.prototype.hasOwnProperty.call(data, 'wopi-controls')) {
          modal.find('.file-wopi-controls').html(data['wopi-controls']);
        }
        link.attr('href', downloadUrl);
        link.attr('data-no-turbolink', true);
        link.attr('data-status', 'asset-present');
        if (data.type === 'previewable') {
          animateSpinner('.file-preview-container', false);
          if (data['wopi-preview-url']) {
            modal.find('.file-preview-container')
              .html(`<iframe class="wopi-file-preview" src="${data['wopi-preview-url']}"></iframe>`);
          } else {
            modal.find('.file-preview-container')
              .append($('<img>')
                .css('opacity', 0)
                .attr('src', data['large-preview-url'])
                .attr('alt', name)
                .on('error', ActiveStoragePreviews.reCheckPreview)
                .on('load', ActiveStoragePreviews.showPreview)
                .click(function(ev) {
                  ev.stopPropagation();
                }));
          }
          if (!readOnly && data.editable) {
            modal.find('.file-edit-link').css('display', '');
            modal.find('.file-edit-link').off().click(function(ev) {
              $.post('/files/' + data.id + '/start_edit_image');
              ev.preventDefault();
              ev.stopPropagation();
              modal.modal('hide');
              //preInitImageEditor(data);
            });
          } else {
            modal.find('.file-edit-link').css('display', 'none');
          }
        } else if (data.type === 'marvinjs') {
          openMarvinEditModal(data, modal);
        } else {
          modal.find('.file-edit-link').css('display', 'none');
          modal.find('.file-preview-container').html(data['preview-icon']);
        }
        if (readOnly) {
          modal.find('#wopi_file_edit_button').remove();
        }
        modal.find('.file-name').text(name);
        modal.modal();
        modal.find('a[disabled=disabled]').click(function(ev) {
          ev.preventDefault();
        });
        $('.modal-backdrop').last().css('z-index', modal.css('z-index') - 1);
      },
      error: function() {
        // TODO
      }
    });*/
  }

  function clearPrevieModal() {
    var modal = $('#filePreviewModal');
    modal.find('.file-preview-container').empty();
    modal.find('.file-wopi-controls').empty();
    modal.find('.file-edit-link').css('display', 'none');
  }

  function openMarvinEditModal(data, modal) {
    modal.find('.file-preview-container')
      .append($('<img>')
        .css('opacity', 0)
        .attr('src', data['large-preview-url'])
        .attr('alt', data.name)
        .on('error', ActiveStoragePreviews.reCheckPreview)
        .on('load', ActiveStoragePreviews.showPreview)
        .click(function(ev) {
          ev.stopPropagation();
        }));
    if (!readOnly && data.editable) {
      modal.find('.file-edit-link').css('display', '');
      modal.find('.file-edit-link').off().click(function(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        modal.modal('hide');
        $.post(data['update-url'] + '/start_editing');
        MarvinJsEditor.open({
          mode: 'edit',
          data: data.description,
          name: data.name,
          marvinUrl: data['update-url']
        });
      });
    } else {
      modal.find('.file-edit-link').css('display', 'none');
    }
  }

  return Object.freeze({
    init: initPreviewModal
  });
}());

FilePreviewModal.init();
