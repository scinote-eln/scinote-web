/* global ActiveStorage GLOBAL_CONSTANTS Promise */

export default {
  methods: {
    directUploadWillStoreFileWithXHR(request) {
      request.upload.addEventListener('progress', () => {
        // Progress checking
      });
    },
    uploadFiles(files) {
      const filesToUploadCntr = files.length;
      let filesUploadedCntr = 0;
      this.showFileModal = false;

      return new Promise((resolve, reject) => {
        $(files).each((_, file) => {
          if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
            // Handle large file size
            return;
          }

          const upload = new ActiveStorage.DirectUpload(file, this.step.attributes.urls.direct_upload_url, this);

          upload.create((error, blob) => {
            if (error) {
              reject(error);
            } else {
              const signedId = blob.signed_id;
              $.post(this.step.attributes.urls.upload_attachment_url, {
                signed_blob_id: signedId
              }, (result) => {
                this.attachments.push(result.data);
              });
              filesUploadedCntr += 1;
              if (filesUploadedCntr === filesToUploadCntr) {
                resolve('done');
              }
            }
          });
        });
      });
    }
  }
};
