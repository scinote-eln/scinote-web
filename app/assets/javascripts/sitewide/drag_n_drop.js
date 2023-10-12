/* global Promise ActiveStorage animateSpinner copyFromClipboard I18n
   Results ResultAssets FilePreviewModal Comments truncateLongString
   DragNDropResults initFormSubmitLinks dragNdropAssetsInit
   GLOBAL_CONSTANTS */

(function(global) {
  'use strict';

  // Copy from clipboard
  global.copyFromClipboard = (function() {
    var UPLOADED_IMAGE = {};

    function retrieveImageFromClipboardAsBlob(pasteEvent, callback) {
      if (pasteEvent.clipboardData === false) {
        if ((typeof callback) === 'function') {
          callback(undefined);
        }
      }

      let items = pasteEvent.clipboardData.items;
      if (items === undefined) {
        if ((typeof callback) === 'function') {
          callback(undefined);
        }
      }

      for (let i = 0; i < items.length; i += 1) {
        if (items[i].type.indexOf('image') !== -1) {
          let blob = items[i].getAsFile();

          if ((typeof callback) === 'function') {
            callback(blob);
          }
        }
      }
    }

    // $(..).modal('hide') don't work properly so here we manually remove the
    // displayed modal
    function hideModalForGood() {
      $('#clipboardPreviewModal').removeClass('in');
      $('.modal-backdrop').remove();
      $('body').removeClass('modal-open');
      $('body').css('padding-right', '');
      $('#clipboardPreviewModal').hide();
    }

    function closeModal() {
      hideModalForGood();
      $('#clipboardPreviewModal').remove();
    }

    function addImageCallback() {
      $('[data-action="addImageFormClipboard"]').on('click', function() {
        let inputArray = [];
        let newName = $('#clipboardImageName').val();
        // check if the name is set
        if (newName && newName.length > 0) {
          let extension = UPLOADED_IMAGE.name.slice(
            (Math.max(0, UPLOADED_IMAGE.name.lastIndexOf('.')) || Infinity) + 1
          );
          // hack to inject custom name in File object
          let name = newName + '.' + extension;
          let blob = UPLOADED_IMAGE.slice(0, UPLOADED_IMAGE.size, UPLOADED_IMAGE.type);
          // make new blob with the correct name;
          let newFile = new File([blob], name, { type: UPLOADED_IMAGE.type });
          inputArray.push(newFile);
        } else { // return the default name
          inputArray.push(UPLOADED_IMAGE);
        }

        // close modal
        closeModal();
        DragNDropResults.init(inputArray);
        // clear all uploaded images
        UPLOADED_IMAGE = {};
      });
    }

    // removes modal from dom
    function destroyModalCallback() {
      let modal = $('#clipboardPreviewModal');
      modal.on('hidden.bs.modal', function() {
        modal.modal('hide').promise().done(function() {
          modal.remove();
        });
        UPLOADED_IMAGE = {};
      });
    }

    // Generate modal html and hook callbacks
    function clipboardPasteModal() {
      var html = `<div id="clipboardPreviewModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                      <div class="modal-content"><div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                          <i class="sn-icon sn-icon-close"></i>
                        </button>
                        <h4 class="modal-title">${I18n.t('assets.from_clipboard.modal_title')}</h4>
                      </div>
                      <div class="modal-body">
                        <p><strong>${I18n.t('assets.from_clipboard.image_preview')}</strong></p>
                        <canvas style="border:1px solid grey;max-width:400px;max-height:300px" id="clipboardPreview" />
                        <p><strong>${I18n.t('assets.from_clipboard.file_name')}</strong></p>
                        <div class="input-group">
                        <input id="clipboardImageName" type="text" class="form-control"
                               placeholder="${I18n.t('assets.from_clipboard.file_name_placeholder')}" aria-describedby="image-name">
                        <span class="input-group-addon" id="image-name"></span></div>
                      </div>
                      <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">${I18n.t('general.cancel')}</button>
                        <button type="button" class="btn btn-success" data-action="addImageFormClipboard">${I18n.t('assets.from_clipboard.add_image')}</button>
                      </div>
                    </div>
                  </div>
                </div><!-- /.modal -->`;
      return $(html).appendTo($('body')).promise().done(function() {
        // display modal
        $('#clipboardPreviewModal').modal('show');
        // add callback to remove modal from DOM
        destroyModalCallback();
        // add callback on image submit
        addImageCallback();
      });
    }

    function listener(pasteEvent) {
      retrieveImageFromClipboardAsBlob(pasteEvent, function(imageBlob) {
        if (imageBlob) {
          clipboardPasteModal().promise().done(function() {
            var canvas = document.getElementById('clipboardPreview');
            var ctx = canvas.getContext('2d');
            var img = new Image();
            img.onload = function() {
              canvas.width = this.width;
              canvas.height = this.height;
              ctx.drawImage(img, 0, 0);
            };
            let URLObj = window.URL || window.webkitURL;
            img.src = URLObj.createObjectURL(imageBlob);
            let extension = imageBlob.name.slice(
              (Math.max(0, imageBlob.name.lastIndexOf('.')) || Infinity) + 1
            );
            $('#image-name').html('.' + extension); // add extension near file name
            // temporary store image blob
            UPLOADED_IMAGE = imageBlob;
          });
        }
      });
    }

    function init() {
      global.addEventListener('paste', listener, false);
    }

    function destroy() {
      global.removeEventListener('paste', listener, false);
    }

    return Object.freeze({
      init: init,
      destroy: destroy
    });
  }());

  // Module to handle file uploading in Results
  global.DragNDropResults = (function() {
    var droppedFiles = [];
    var isValid = true;
    var totalSize = 0;
    var fileMaxSizeMb;
    var fileMaxSize;
    var itemsNames = {};

    function disableSubmitButton() {
      $('.save-result').prop('disabled', true);
    }

    function enableSubmitButton() {
      $('.save-result').prop('disabled', false).focus();
    }

    function filerAndCheckFiles() {
      for (let i = 0; i < droppedFiles.length; i += 1) {
        if (droppedFiles[i].isValid === false) {
          return false;
        }
      }
      return (droppedFiles.length > 0);
    }

    function dragNdropAssetsOff() {
      $('body').off('drag dragstart dragend dragover dragenter dragleave drop');
      $('.is-dragover').hide();
    }

    function destroyAll() {
      dragNdropAssetsOff();
      droppedFiles = [];
      isValid = true;
      totalSize = 0;
    }

    // return the status of files if they are ready to submit
    function filesStatus() {
      return isValid;
    }

    function validateTotalSize() {
      if (totalSize > fileMaxSize) {
        isValid = false;
        disableSubmitButton();
        $.each($('.panel-result-attachment-new'), function() {
          if (!$(this).find('p').hasClass('dnd-total-error')) {
            $(this)
              .find('.panel-body')
              .append("<p class='dnd-total-error'>" + I18n.t('general.file.total_size', { size: fileMaxSizeMb }) + '</p>');
          }
        });
      } else {
        $('.dnd-total-error').remove();
        if (filerAndCheckFiles()) {
          isValid = true;
          enableSubmitButton();
        }
      }
    }

    function submitResultForm(url, formData) {
      $.ajax({
        url: url,
        method: 'POST',
        data: formData,
        contentType: false,
        processData: false,
        success: function(data) {
          animateSpinner(null, false);
          $('#new-result-assets-select').parent().remove();
          $(data.html).prependTo('#results').promise().done(function() {
            $.each($('[data-container="new-reports"]').find('.result'), function() {
              initFormSubmitLinks($(this));
              ResultAssets.applyEditResultAssetCallback();
              Results.toggleResultEditButtons(true);
              Comments.init();
              ResultAssets.initNewResultAsset();
              Results.expandResult($(this));
            });
          });
          $('#results-toolbar').show();
        },
        error: function() {
          animateSpinner();
        }
      });
    }

    // appent the files to the form before submit
    function appendFilesToForm(ev, fd) {
      const form = $(ev.target.form);
      const url = form.find('#drag-n-drop-assets').data('directUploadUrl');
      const lastIndex = droppedFiles.length - 1;

      let index = 0;

      const uploadFile = (file) => {
        const upload = new ActiveStorage.DirectUpload(file, url);

        upload.create((error, blob) => {
          if (error) {
            $.each($('.panel-result-attachment-new'), function() {
              if (!$(this).find('p').hasClass('dnd-total-error')) {
                $(this)
                  .find('.panel-body')
                  .append("<p class='dnd-total-error'>" + I18n.t('general.file.upload_failure') + '</p>');
              }
            });
            animateSpinner(null, false);
          } else {
            fd.append('results_names[' + index + ']', $('input[name="results[name][' + index + ']"]').val());
            fd.append('results_files[' + index + '][signed_blob_id]', blob.signed_id);
            if (index === lastIndex) {
              submitResultForm($(ev.target).attr('data-href'), fd);
              destroyAll();
              return;
            }
            index += 1;
            uploadFile(droppedFiles[index]);
          }
        });
      };

      uploadFile(droppedFiles[index]);
    }

    /* eslint no-param-reassign: ["error", { "props": false }] */
    function validateFilesSize(file) {
      var fileSize = file.size;
      totalSize += parseInt(fileSize, 10);
      if (fileSize > fileMaxSize) {
        file.isValid = false;
        disableSubmitButton();
        return "<p class='dnd-error'>" + I18n.t('general.file.size_exceeded', { file_size: fileMaxSizeMb }) + '</p>';
      }
      return '';
    }

    function validateTextSize(input) {
      if (input.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
        $(input).parent().find('.dnd-error').remove();
        $(input).after("<p class='dnd-error'>" + I18n.t('general.text.length_too_long', { max_length: GLOBAL_CONSTANTS.NAME_MAX_LENGTH }) + '</p>');
        isValid = false;
      } else {
        $(input).parent().find('.dnd-error').remove();
        isValid = true;
      }
    }

    function uploadedAssetPreview(asset, i) {
      var html = `<div class="panel panel-default panel-result-attachment-new" data-item-uuid="${asset.uuid}">
                    <div class="panel-heading">
                      <span class="sn-icon sn-icon-files"></span>
                      ${I18n.t('assets.drag_n_drop.file_label')}
                      <div class="pull-right">
                        <a data-item-id="${asset.uuid}" href="#">
                          <span class="sn-icon sn-icon-close"></span>
                        </a>
                      </div>
                    </div>
                    <div class="panel-body">
                      <div class="form-group">
                        <label class="control-label">Name</label>
                        <input type="text" class="form-control file-name-field"
                               rel="results[name]" name="results[name][${i}]">
                      </div>
                      <div class="form-group">
                        <label class="control-label">${I18n.t('assets.drag_n_drop.file_label')}:</label>
                        ${truncateLongString(asset.name, GLOBAL_CONSTANTS.FILENAME_TRUNCATION_LENGTH)}
                        ${validateFilesSize(asset)}
                      </div>
                    </div>
                  </div>`;
      return html;
    }

    function processResult(ev) {
      ev.preventDefault();
      ev.stopPropagation();

      if (isValid && filerAndCheckFiles()) {
        animateSpinner();

        let formData = new FormData();

        appendFilesToForm(ev, formData);
      }
    }

    function restoreItemName(uuid) {
      $(`.panel-result-attachment-new[data-item-uuid="${uuid}"]`)
        .find('input[rel="results[name]"]').val((itemsNames[uuid] || ''));
    }

    function saveItemsNames() {
      $('.panel-result-attachment-new').each(function() {
        const panel = $(this);
        itemsNames[panel.data('item-uuid')] = panel.find('input[rel="results[name]"]').val();
      });
    }

    function removeItemHandler(uuid) {
      $('[data-item-id="' + uuid + '"]').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        e.stopPropagation();
        let $el = $(this);
        let index = droppedFiles.findIndex((file) => {
          return file.uuid === $el.data('item-id');
        });
        totalSize -= parseInt(droppedFiles[index].size, 10);
        droppedFiles.splice(index, 1);
        validateTotalSize();
        $el.closest('.panel-result-attachment-new').remove();
      });
    }

    // loops through a list of files and display each file in a separate panel
    function listItems() {
      totalSize = 0;
      itemsNames = {};

      saveItemsNames();

      $('.panel-result-attachment-new').remove();
      if (droppedFiles.length < 1) {
        disableSubmitButton();
      } else {
        dragNdropAssetsOff();

        for (let i = 0; i < droppedFiles.length; i += 1) {
          $('#new-result-assets-select')
            .after(uploadedAssetPreview(droppedFiles[i], i))
            .promise()
            .done(function() {
              const uuid = droppedFiles[i].uuid;
              removeItemHandler(uuid);
              restoreItemName(uuid);
              $('.panel-result-attachment-new').on('change', 'input[rel="results[name]"]', function() {
                DragNDropResults.validateTextSize(this);
              });
            });
        }
        validateTotalSize();
        dragNdropAssetsInit();
        setTimeout(() => {
          $('.file-name-field').focus();
        }, 200);
      }
    }

    function init(files) {
      fileMaxSizeMb = GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB;
      fileMaxSize = fileMaxSizeMb * 1024 * 1024;

      for (let i = 0; i < files.length; i += 1) {
        files[i].uuid = Math.random().toString(36);
        droppedFiles.unshift(files[i]);
      }
      listItems();
    }

    return Object.freeze({
      init: init,
      listItems: listItems,
      destroyAll: destroyAll,
      filesStatus: filesStatus,
      validateTextSize: validateTextSize,
      processResult: processResult
    });
  }());

  global.dragNdropAssetsInit = function() {
    var inWindow = true;

    $('body')
      .on('drag dragstart dragend dragover dragenter dragleave drop', (e) => {
        e.preventDefault();
        e.stopPropagation();
      })
      .on('dragover', function() {
        inWindow = true;
        $('.is-dragover').show();
      })
      .on('dragleave', function() {
        inWindow = false;
        setTimeout(function() {
          if (!inWindow) {
            $('.is-dragover').hide();
          }
        }, 5000);
      })
      .on('drop', function(e) {
        $('.is-dragover').hide();
        let files = e.originalEvent.dataTransfer.files;
        DragNDropResults.init(files);
      });

    copyFromClipboard.init();
  };
}(window));
