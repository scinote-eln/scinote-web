(function (exports) {

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
      if(type === "image/jpeg") {
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
  // size and spoofing) and generates posts for S3 server file uploading
  // (each post for different size of the same file)
  // We do this synchronically, because we need to verify all files
  // before uploading them
  function fetchUploadSignature(file, signUrl, cb) {
    var csrfParam = $("meta[name=csrf-param]").attr("content");
    var csrfToken = $("meta[name=csrf-token]").attr("content");

    var formData = new FormData();
    formData.append("file", file);

    $.ajax({
      url : signUrl,
      type : 'POST',
      data : formData,
      async : false,
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
  function uploadData(postData, cb) {
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
        cb(I18n.t("errors.upload"));
      }
    }
    xhr.open("POST", url);
    xhr.send(fd);
  }

  var styleOptionRe = /(\d+)x(\d+)/i;

  function parseStyleOption(option) {
    var m = option.match(styleOptionRe);

    return {
      width: m && m[1] || 150,
      height: m && m[2] || 150
    };
  }

  // Validates files on this server and uploads them to S3 server
  exports.directUpload = function (ev, fileInputs, signUrl, cb) {
    var noErrors = true;
    var inputPointer = 0;
    animateSpinner();

    function processFile () {
      var fileInput = fileInputs.get(inputPointer);
      if (!fileInput || !fileInput.files[0]) {
        return;
      }
      var file = fileInput.files[0];
      inputPointer++;

      fetchUploadSignature(file, signUrl, function (data) {

        function processError(errMsgs) {
          renderFormError(ev, fileInput, errMsgs);
          noErrors = false;
        }

        function processPost(error) {
          // File post error handling
          if (error) {
            processError(error);
          }

          var postData = posts[postPosition];
          if (!postData) {
            animateSpinner(null, false);
            return;
          }
          postData.fileName = file.name;
          postPosition += 1;

          if (postData.style_option) {
            var styleSize = parseStyleOption(postData.style_option);
            generateThumbnail(file, postData.mime_type, styleSize.width,
              styleSize.height, function (blob) {

              postData.file = blob;
              uploadData(postData, processPost);
            });
           } else {
            postData.file = file;
            uploadData(postData, processPost);
          }
        }

        // File signature error handling
        if (_.isUndefined(data)) {
          processError(I18n.t("errors.upload"));
        }
        if (data.status === "error") {
          processError(jsonToValuesArray(data.errors));
        }

        processFile();
        if(noErrors) {
          // Use file input to pass file info on submit
          cb(fileInput, data.asset_id);

          var posts = data.posts;
          var postPosition = 0;
          processPost();
        }
      });
    }

    processFile();
  };

}(this));
