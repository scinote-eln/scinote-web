(function (exports) {

  var styleOptionRe = /(\d+)x(\d+)/i;

  function parseStyleOption(option) {
    var m = option.match(styleOptionRe);

    return {
      width: m && m[1] || 150,
      height: m && m[2] || 150
    };
  }

  /*
   * Edits (size, quality, parameters) image file for S3 server uploading.
   */
  function generateThumbnail(origFile, type, max_width, max_height, cb) {
    var fileRequest = $.Deferred();
    var img = new Image;
    var canvas = document.createElement('canvas');
    var ctx = canvas.getContext('2d');
    // todo allow for different x/y ratio
    canvas.width = max_width;
    canvas.height = max_height;

    img.onload = function () {
      var size;
      var offsetX = 0;
      var offsetY = 0;

      if (this.width > this.height) {
        size = this.height;
        offsetX = (this.width - this.height) / 2;
      } else {
        size = this.width;
        offsetY = (this.height - this.width) / 2;
      }
      if (type === 'image/jpeg') {
        type = 'image/jpg';
      }

      ctx.drawImage(this, offsetX, offsetY, size, size, 0, 0,
        canvas.width, canvas.height);
      canvas.toBlob(function (blob) {
        fileRequest.resolve(cb(blob));
      }, type, 0.8);
    };
    // Must be after onload, otherwise it could load before we would
    // capture the event
    img.src = URL.createObjectURL(origFile);

    return fileRequest.promise();
  }

  /*
   * The server checks if files are OK (presence, size and spoofing)
   * and only then generates posts for S3 server file uploading
   * (each post for different size/style of the same file).
   */
  function fetchUploadSignature(ev, fileInput, file, signUrl) {
    var formData = new FormData();
    formData.append('file', file);

    return $.ajax({
      url: signUrl,
      type: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      error: function (xhr) {
        var errMsg;
        try {
          // File error
          var jsonData = $.parseJSON(xhr.responseText);
          errMsg = jsonToValuesArray(jsonData.errors);
        } catch(err) {
          // Connection error
          errMsg = I18n.t('general.file.upload_failure');
        }
        renderFormError(ev, fileInput, errMsg);
      }
    });
  }

  /*
   * Upload file to S3 server.
   */
  function uploadFile(postData, ev, fileInput) {
    var url = postData.url;
    var fields = postData.fields;
    var formData = new FormData();
    for (var k in fields) {
      formData.append(k, fields[k]);
    }
    formData.append('file', postData.file, postData.fileName);

    return $.ajax({
      url: url,
      type: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      error: function (xhr) {
        var errMsg;
        try {
          // File error
          var $xmlData = $(xhr.responseText);
          errMsg = $xmlData.find('Message').text().strToErrorFormat();
        } catch(err) {
          // Connection error
          errMsg = I18n.t('general.file.upload_failure');
        }
        renderFormError(ev, fileInput, errMsg);
      }
    });
  }

  /*
   * Proccesses file's posts and uploads them.
   */
  function processPosts(ev, fileInput, posts, fileRequests) {
    var file = fileInput.files[0];
    _.each(posts, function (postData) {
      postData.fileName = file.name;
      if (postData.style_option) {
        // Picture file
        var styleSize = parseStyleOption(postData.style_option);
        var fileRequest = generateThumbnail(file, postData.mime_type, styleSize.width,
          styleSize.height, function (blob) {

            postData.file = blob;
            uploadFile(postData, ev, fileInput);
        });
      } else {
        // Other file
        postData.file = file;
        var fileRequest = uploadFile(postData, ev, fileInput);
      }
      fileRequests.push(fileRequest);
    });
  }

  function beforeUpload(ev) {
    animateSpinner();
    preventLeavingPage(true, I18n.t('general.file.uploading'));
    ev.preventDefault();
  }

  function afterUpload() {
    animateSpinner(null, false);
    preventLeavingPage(false);
  }

  /*
   * Spoof checks files on server and uploads them to S3 server.
   *
   * First we asyncronously spoof check files on server and generate post
   * requests (fetchUploadSignature), if OK the post requests are used to uplaod
   * files asyncronously to S3 (uploadFile), and if successful the form is
   * submitted, otherwise no file is saved and errors are shown.
   * If any post fails, the user is allowed to leave the page, but other files
   * are still being uploaded because of asynchronous behaviour, so that errors
   * for other files can still show afterwards.
   *
   * TODO On S3 server upload error the other files that were already
   * asynchronously uploaded remain on the server, but should be deleted - this
   * should generally not happen, because all files should fail to upload in
   * such cases (like S3 server connection error), except if user cancels the
   * upload while still in progress. But this can be abused! One way to solve
   * it is to make request to our server for each file seperatelly, and not for
   * all together as it is now, despite being less efficient. To make it
   * bulletproof, post requests should be issued on server-side.
   *
   * @param {boolean} willPageRefresh Whether page refreshes or is updated with
   *  AJAX. Everything should be done through AJAX, however.
   */
  exports.directUpload = function (ev, signUrl, willPageRefresh) {
    if (typeof willPageRefresh === 'undefined') {
      willPageRefresh = false;
    }
    var $form = $(ev.target.form);
    $form.clearFormErrors();
    $form.removeBlankFileForms();
    var $fileInputs = $form.find('input[type=file]');
    var signRequests = [];

    if ($fileInputs.length) {
      // Before file processing and uploading
      beforeUpload(ev);

      // Spoof checks files and, if OK, gets upload post requests
      var anyFile = false;
      _.each($fileInputs, function (fileInput) {
        var file = fileInput.files[0];
        if (!_.isUndefined(file)) {
          signRequests.push(
            fetchUploadSignature(ev, fileInput, file, signUrl)
          );
          anyFile = true;
        }
      });
      if (!anyFile) {
        // No files present
        afterUpload();
        $form.submit();
        return;
      }

      $.when.apply($, signRequests).then(function () {
        // After successful file spoof check and upload post requests fetching
        if (signRequests.length) {
          var fileRequests = [];

          if (signRequests.length == 1) {
            arguments = [arguments];
          }
          $.each(arguments, function (fileIdx, responseData) {
            $fileInput = $fileInputs[fileIdx];
            var jqXHR  = responseData[2];
            var data = JSON.parse(jqXHR.responseText);
            processPosts(ev, $fileInput, data.posts, fileRequests);
          });

          $.when.apply($, fileRequests).then(function () {
            // After successful posts processing and file uploading
            if (willPageRefresh) {
              preventLeavingPage(false);
            } else {
              $form.onAjaxComplete(afterUpload);
            }
            $form.submit();
          },// After unsuccessful posts processing and file uploading
          afterUpload);
        }
      }, // After unsuccessful file spoof check and posts fetching
      afterUpload);
    }
  };

}(this));
