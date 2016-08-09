(function (exports) {

  var styleOptionRe = /(\d+)x(\d+)/i;

  function parseStyleOption(option) {
    var m = option.match(styleOptionRe);

    return {
      width: m && m[1] || 150,
      height: m && m[2] || 150
    };
  }

  // Edits (size, quality, parameters) image file for S3 server uploading
  function generateThumbnail(origFile, type, max_width, max_height, cb) {
    var img = new Image;
    var canvas = document.createElement("canvas");
    var ctx = canvas.getContext("2d");
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
      if (type === "image/jpeg") {
        type = "image/jpg";
      }

      ctx.drawImage(this, offsetX, offsetY, size, size, 0, 0,
        canvas.width, canvas.height);
      canvas.toBlob(function (blob) {
        cb(blob);
      }, type, 0.8);
    };
    img.src = URL.createObjectURL(origFile);
  }

  // This server checks if files are OK (correct file type, presence,
  // size and spoofing) and only then generates posts for S3 server
  // file uploading (each post for different size of the same file)
  function fetchUploadSignature(file, signUrl, cb) {
    var csrfParam = $("meta[name=csrf-param]").attr("content");
    var csrfToken = $("meta[name=csrf-token]").attr("content");

    var formData = new FormData();
    formData.append("file", file);

    $.ajax({
      url : signUrl,
      type : 'POST',
      data : formData,
      processData: false,
      contentType: false,
      complete : function(xhr) {
        if (xhr.readyState === 4) { // complete
          var data = JSON.parse(xhr.responseText);
          cb(data);
        } else if (xhr.readyState == 0) { // connection error
          cb();
        }
      }
    });
  }

  // Upload file to S3 server
  function uploadFile(postData, cb) {
    var xhr = new XMLHttpRequest;
    var fd = new FormData();
    var fields = postData.fields;
    var url = postData.url;

    for (var k in fields) {
      fd.append(k, fields[k]);
    }
    fd.append("file", postData.file, postData.fileName);

    xhr.onreadystatechange = function() {
      if (xhr.readyState === 4) { // complete
        cb();
      } else if (xhr.readyState == 0) { // connection error
        cb(I18n.t("general.file.upload_failure"));
      }
    }
    xhr.open("POST", url);
    xhr.send(fd);
  }

  // For each file proccesses its posts and uploads them
  // If one post fails, the user is allowed to leave page,
  // but other files are still being uplaoded because of
  // asynchronous behaviour, so errors for other files may
  // can still show afterwards
  // TODO On S3 server uplaod error the other files that
  // were already asynchronously uploaded remain, but
  // should be deleted - this should generally not happen,
  // because all files should fail to upload in such cases
  // (connection error)
  function  uploadFiles(ev, fileInputs, datas, cb) {
    var noErrors = true;
    $.each(datas, function(fileIndex, data) {
      var fileInput = fileInputs.get(fileIndex);
      var file = fileInput.files[0];

      function processPost(error) {
        // File upload error handling
        if (error) {
          renderFormError(ev, fileInput, error);
          noErrors = false;
          animateSpinner(null, false);
          return;
        }

        var postData = posts[postIndex];
        if (!postData) {
          if (fileIndex === datas.length-1 && noErrors) {
            // After successful file processing and uploading
            $.each(datas, function(fileIndex, data) {
              // Use file input to pass file info on submit
              var fileInput = fileInputs.get(fileIndex);
              cb(fileInput, data.asset_id);
            });
            animateSpinner(null, false);
            $(ev.target.form).submit();
          }
          return;
        }
        postData.fileName = file.name;
        postIndex++;

        if (postData.style_option) {
          // Picture file
          var styleSize = parseStyleOption(postData.style_option);
          generateThumbnail(file, postData.mime_type, styleSize.width,
            styleSize.height, function (blob) {

            postData.file = blob;
            uploadFile(postData, processPost);
          });
         } else {
          // Other file
          postData.file = file;
          uploadFile(postData, processPost);
        }
      }

      var posts = data.posts;
      var postIndex = 0;
      processPost();
    });
  }

  // Validates files on  server and uploads them to S3 server
  //
  // First we validate files on server and generate post requests (fetchUploadSignature),
  // if OK the post requests are used to uplaod files asyncronously to S3 (uploadFiles),
  // and if successful the form is submitted, otherwise no file is saved
  exports.directUpload = function (ev, fileInputs, signUrl, cb) {
    var noErrors = true;
    var inputsPosts = []

    function processFile(fileIndex) {
      var fileInput = fileInputs.get(fileIndex);
      if (!fileInput || !fileInput.files[0]) {
        // After file processing
        if(fileIndex !== 0) {
          if(noErrors) {
            uploadFiles(ev, fileInputs, inputsPosts, cb);
          } else {
            animateSpinner(null, false);
          }
        }
        return;
      }

      if (fileIndex === 0) {
        // Before file processing and uploading
        animateSpinner(null, true, undefined, I18n.t("general.file.uploading"));
        ev.preventDefault();
        ev.stopPropagation();
      }

      var file = fileInput.files[0];
      fetchUploadSignature(file, signUrl, function (data) {
        // File signature error handling
        if (_.isUndefined(data)) {
          renderFormError(ev, fileInput, I18n.t("general.file.upload_failure"));
          noErrors = false;
        }
        else if (data.status === "error") {
          renderFormError(ev, fileInput, jsonToValuesArray(data.errors));
          noErrors = false;
        } else {
          inputsPosts.push(data);
        }

        processFile(fileIndex+1);
      });
    }

    processFile(0);
  };

}(this));
