/*
 global ActiveStorage Promise I18n GLOBAL_CONSTANTS
*/
/* eslint-disable no-unused-vars */

var AssetColumnHelper = (function() {
  function uploadFiles($fileInputs, directUploadUrl) {
    let filesToUploadCntr = 0;
    let filesUploadedCntr = 0;
    let filesForUpload = [];

    $fileInputs.each(function(_, f) {
      let $f = $(f);
      if ($f.val()) {
        filesToUploadCntr += 1;
        filesForUpload.push($f);
      }
    });

    return new Promise((resolve, reject) => {
      if (filesToUploadCntr === 0) {
        resolve('done');
        return;
      }

      $(filesForUpload).each(function(_, $el) {
        let upload = new ActiveStorage.DirectUpload($el[0].files[0], directUploadUrl);

        upload.create(function(error, blob) {
          if (error) {
            reject(error);
          } else {
            $el
              .prev('.file-hidden-field-container')
              .html(`<input type="hidden"
                     form="${$el.attr('form')}"
                     name="repository_cells[${$el.data('col-id')}]"
                     value="${blob.signed_id}"/>`);

            filesUploadedCntr += 1;

            if (filesUploadedCntr === filesToUploadCntr) {
              resolve('done');
            }
          }
        });
        return true;
      });
    });
  }

  function renderCell($cell, formId, columnId) {
    let empty = $cell.is(':empty');
    let fileName = $cell.find('a.file-preview-link').text();
    let placeholder = I18n.t('repositories.table.assets.select_file_btn', { max_size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB });
    let rowId = $cell.parent().attr('id');

    $cell.html(`
      <div class="file-editing">
        <div class="file-hidden-field-container hidden"></div>
        <input class=""
               id="repository_file_${columnId}_${rowId}"
               form="${formId}"
               type="file"
               data-col-id="${columnId}"
               data-is-empty="${empty}"
               value=""
               data-type="RepositoryAssetValue">
        <div class="file-upload-button ${empty ? 'new-file' : ''}">
          <i class="sn-icon sn-icon-files icon"></i>
          <label data-placeholder="${placeholder}" for="repository_file_${columnId}_${rowId}">${fileName}</label>
          <span class="delete-action sn-icon sn-icon-delete"> </span>
        </div>
      </div>`);
  }

  return {
    uploadFiles: uploadFiles,
    renderCell: renderCell
  };
}());
