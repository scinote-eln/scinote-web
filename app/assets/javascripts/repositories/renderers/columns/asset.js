/*
 global ActiveStorage Promise
*/
/* eslint-disable no-unused-vars */

var Asset = (function() {
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

  return {
    uploadFiles: uploadFiles
  };
}());
