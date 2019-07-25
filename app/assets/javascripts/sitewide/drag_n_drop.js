/* global Promise ActiveStorage animateSpinner copyFromClipboard I18n
   Results ResultAssets FilePreviewModal Comments truncateLongString
   DragNDropSteps DragNDropResults initFormSubmitLinks dragNdropAssetsInit */

(function(global) {
  'use strict';

  // Copy from clipboard
  global.copyFromClipboard = (function() {
    var UPLOADED_IMAGE = {};
    var LOCATION = '';

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
        // reuse file upload from drag'n drop :)
        if (LOCATION === 'steps') {
          DragNDropSteps.init(inputArray);
        } else {
          DragNDropResults.init(inputArray);
        }
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
      var html = '<div id="clipboardPreviewModal" class="modal fade" ';
      html += 'tabindex="-1" role="dialog" aria-hidden="true">';
      html += '<div class="modal-dialog" role="document">';
      html += '<div class="modal-content"><div class="modal-header">';
      html += '<button type="button" class="close" data-dismiss="modal"';
      html += ' aria-label="Close"><span aria-hidden="true">&times;</span>';
      html += '</button><h4 class="modal-title">' + I18n.t('assets.from_clipboard.modal_title') + '</h4>';
      html += '</div><div class="modal-body"><p><strong>' + I18n.t('assets.from_clipboard.image_preview') + '</strong></p>';
      html += '<canvas style="border:1px solid grey;max-width:400px;max-height:300px" id="clipboardPreview" />';
      html += '<p><strong>' + I18n.t('assets.from_clipboard.file_name') + '</strong></p>';
      html += '<div class="input-group">';
      html += '<input id="clipboardImageName" type="text" class="form-control" ';
      html += 'placeholder="' + I18n.t('assets.from_clipboard.file_name_placeholder') + '" aria-describedby="image-name">';
      html += '<span class="input-group-addon" id="image-name"></span></div>';
      html += '</div><div class="modal-footer">';
      html += '<button type="button" class="btn btn-default" data-dismiss="modal">' + I18n.t('general.cancel') + '</button>';
      html += '<button type="button" class="btn btn-success" data-action="addImageFormClipboard">' + I18n.t('assets.from_clipboard.add_image') + '</button>';
      html += '</div></div></div></div><!-- /.modal -->';
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

    function init(location) {
      LOCATION = location;
      global.addEventListener('paste', listener, false);
      $.initTooltips();
    }

    function destroy() {
      global.removeEventListener('paste', listener, false);
    }

    return Object.freeze({
      init: init,
      destroy: destroy
    });
  }());

  // Module to handle file uploading in Steps
  global.DragNDropSteps = (function() {
    var droppedFiles = [];
    var filesValid = true;
    var totalSize = 0;
    var fileMaxSizeMb;
    var fileMaxSize;
    var uploadedFilesCounter = 0;

    // return the status of files if they are ready to submit
    function filesStatus() {
      return filesValid;
    }

    function clearFiles() {
      droppedFiles = [];
    }

    function incrementUploadedFilesCounter() {
      uploadedFilesCounter += 1;
    }

    function getUploadedFilesCounter() {
      return uploadedFilesCounter;
    }

    function dragNdropAssetsOff() {
      $('body').off('drag dragstart dragend dragover dragenter dragleave drop');
      $('.is-dragover').hide();
      // remove listeners for clipboard images
      copyFromClipboard.destroy();
    }

    // append the files to the form before submit
    function appendFilesToForm(ev) {
      return new Promise((resolve, reject) => {
        const form = $(ev.target).closest('form').get(0);
        const url = $(form).find('#drag-n-drop-assets').data('directUploadUrl');
        const regex = /step\[assets_attributes\]\[[0-9]*\]\[id\]/;
        const numberOfFiles = droppedFiles.length;
        let prevEls = $('input').filter(function() {
          return this.name.match(regex);
        });

        let fd = new FormData(form);

        uploadedFilesCounter = 0;
        fd.delete('step[file][]');

        if (droppedFiles.length === 0) {
          resolve(fd);
          return;
        }

        for (let i = 0; i < droppedFiles.length; i += 1) {
          let upload = new ActiveStorage.DirectUpload(droppedFiles[i], url);
          let index = i + prevEls.length;

          upload.create(function(error, blob) {
            if (error) {
              reject(error);
            } else {
              fd.append('step[assets_attributes][' + index + '][signed_blob_id]', blob.signed_id);
              incrementUploadedFilesCounter();
              if (getUploadedFilesCounter() === numberOfFiles) {
                resolve(fd);
              }
            }
          });
        }

        filesValid = true;
        totalSize = 0;
        dragNdropAssetsOff();
      });
    }

    function disableSubmitButton() {
      $('.step-save').prop('disabled', true);
    }

    function enableSubmitButton() {
      $('.step-save').prop('disabled', false);
    }

    function filerAndCheckFiles() {
      for (let i = 0; i < droppedFiles.length; i += 1) {
        if (droppedFiles[i].isValid === false) {
          return false;
        }
      }
      return (droppedFiles.length > 0);
    }

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

    function validateTotalSize() {
      if (totalSize > fileMaxSize) {
        filesValid = false;
        disableSubmitButton();
        $.each($('.panel-step-attachment-new'), function() {
          if (!$(this).find('p').hasClass('dnd-total-error')) {
            $(this)
              .find('.panel-body')
              .append("<p class='dnd-total-error'>" + I18n.t('general.file.total_size', { size: fileMaxSizeMb }) + '</p>');
          }
        });
      } else {
        $('.dnd-total-error').remove();
        if (filerAndCheckFiles()) {
          filesValid = true;
          enableSubmitButton();
        }
      }
    }

    function uploadedAssetPreview(asset, i) {
      var html = '<div class="attachment-placeholder pull-left new">';
      html += '<div class="attachment-thumbnail no-shadow new %>">';
      html += '<i class="fas fa-image"></i>';
      html += '</div>';
      html += '<div class="attachment-label">';
      html += truncateLongString(asset.name, $(document.body).data('filename-max-length'));
      html += '</div>';
      html += '<div class="spencer-bonnet-modif">';
      html += '</div>';
      html += '<div class="remove-icon pull-right">';
      html += '<a data-item-id="' + i + '" href="#">';
      html += '<span class="fas fa-trash"></span>';
      html += '</a>  </div>';
      html += validateFilesSize(asset);
      html += '</div>';

      return html;
    }

    function removeItemHandler(id, callback) {
      $('[data-item-id="' + id + '"]').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        e.stopPropagation();
        let $el = $(this);
        let index = $el.data('item-id');
        totalSize -= parseInt(droppedFiles[index].size, 10);
        droppedFiles.splice(index, 1);
        callback();
      });
    }

    // loops through a list of files and display each file in a separate panel
    function listItems() {
      totalSize = 0;
      enableSubmitButton();
      $('.attachment-placeholder.new').remove();
      dragNdropAssetsOff();

      for (let i = 0; i < droppedFiles.length; i += 1) {
        $('.attachments.edit')
          .append(uploadedAssetPreview(droppedFiles[i], i))
          .promise()
          .done(function() {
            removeItemHandler(i, listItems);
          });
      }
      validateTotalSize();
      dragNdropAssetsInit('steps');
    }

    function init(files) {
      fileMaxSizeMb = $(document.body).data('file-max-size-mb');
      fileMaxSize = fileMaxSizeMb * 1024 * 1024;
      for (let i = 0; i < files.length; i += 1) {
        droppedFiles.push(files[i]);
      }
      listItems();
    }

    return Object.freeze({
      init: init,
      appendFilesToForm: appendFilesToForm,
      listItems: listItems,
      filesStatus: filesStatus,
      clearFiles: clearFiles
    });
  }());

  // Module to handle file uploading in Results
  global.DragNDropResults = (function() {
    var droppedFiles = [];
    var isValid = true;
    var totalSize = 0;
    var fileMaxSizeMb;
    var fileMaxSize;

    function disableSubmitButton() {
      $('.save-result').prop('disabled', true);
    }

    function enableSubmitButton() {
      $('.save-result').prop('disabled', false);
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
              Results.applyCollapseLinkCallBack();
              Results.toggleResultEditButtons(true);
              FilePreviewModal.init();
              Comments.init();
              ResultAssets.initNewResultAsset();
              Results.expandResult($(this));
            });
          });
          $('#results-toolbar').show();
        },
        error: function() {
          animateSpinner();
          location.reload();
        }
      });
    }

    // appent the files to the form before submit
    function appendFilesToForm(ev, fd) {
      const form = $(ev.target.form);
      const url = form.find('#drag-n-drop-assets').data('directUploadUrl');
      const numberOfFiles = droppedFiles.length;

      let resultNames = [];

      $.each($('input[rel="results[name]"]'), function() {
        resultNames.push($(this).val());
      });

      resultNames.reverse();

      for (let i = 0; i < numberOfFiles; i += 1) {
        let upload = new ActiveStorage.DirectUpload(droppedFiles[i], url);

        upload.create(function(error, blob) {
          if (error) {
            // Handle the error
          } else {
            fd.append('results_names[' + i + ']', resultNames[i]);
            fd.append('results_files[' + i + '][signed_blob_id]', blob.signed_id);
            if ((i + 1) === numberOfFiles) {
              submitResultForm($(ev.target).attr('data-href'), fd);
              destroyAll();
            }
          }
        });
      }
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
      if (input.value.length > $(document.body).data('name-max-length')) {
        $(input).parent().find('.dnd-error').remove();
        $(input).after("<p class='dnd-error'>" + I18n.t('general.text.length_too_long', { max_length: $(document.body).data('name-max-length') }) + '</p>');
        isValid = false;
      } else {
        $(input).parent().find('.dnd-error').remove();
        isValid = true;
      }
    }

    function uploadedAssetPreview(asset, i) {
      var html = '<div class="panel panel-default panel-result-attachment-new">';
      html += '<div class="panel-heading">';
      html += '<span class="fas fa-paperclip"></span>';
      html += I18n.t('assets.drag_n_drop.file_label');
      html += '<div class="pull-right">';
      html += '<a data-item-id="' + i + '" href="#">';
      html += '<span class="fas fa-times"></span></a></div></div>';
      html += '<div class="panel-body"><div class="form-group">';
      html += '<label class="control-label">Name</label>';
      html += '<input type="text" class="form-control" ';
      html += 'onChange="DragNDropResults.validateTextSize(this)"';
      html += ' rel="results[name]" name="results[name][' + i + ']">';
      html += '</div><div class="form-group"><label class="control-label">';
      html += I18n.t('assets.drag_n_drop.file_label') + ':</label> ';
      html += truncateLongString(asset.name, $(document.body).data('filename-max-length'));
      html += validateFilesSize(asset);
      html += '</div></div>';
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

    function removeItemHandler(id, callback) {
      $('[data-item-id="' + id + '"]').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        e.stopPropagation();
        let $el = $(this);
        let index = $el.data('item-id');
        totalSize -= parseInt(droppedFiles[index].size, 10);
        droppedFiles.splice(index, 1);
        callback();
      });
    }

    // loops through a list of files and display each file in a separate panel
    function listItems() {
      totalSize = 0;
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
              removeItemHandler(i, listItems);
            });
        }
        validateTotalSize();
        dragNdropAssetsInit('results');
      }
    }

    function init(files) {
      fileMaxSizeMb = $(document.body).data('file-max-size-mb');
      fileMaxSize = fileMaxSizeMb * 1024 * 1024;
      for (let i = 0; i < files.length; i += 1) {
        droppedFiles.push(files[i]);
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

  global.dragNdropAssetsInit = function(location) {
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
        if (location === 'steps') {
          DragNDropSteps.init(files);
        } else {
          DragNDropResults.init(files);
        }
      });

    copyFromClipboard.init(location);
  };
}(window));
