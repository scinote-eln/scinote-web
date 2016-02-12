(function (exports) {

  function generateThumbnail(origFile, type, max_width, max_height, cb) {
    var img = new Image;
    var canvas = document.createElement("canvas");
    var ctx = canvas.getContext("2d");
    // todo allow for different x/y ratio

    canvas.width = max_width;
    canvas.height = max_height;
    img.src = URL.createObjectURL(origFile);

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

      ctx.drawImage(this, offsetX, offsetY, size, size, 0, 0, canvas.width, canvas.height);

      canvas.toBlob(function (blob) {
        cb(blob);
      }, type, 0.8)
    };
  }


  function fetchUploadSignature(file, origId, signUrl, cb) {
    var csrfParam = $("meta[name=csrf-param]").attr("content");
    var csrfToken = $("meta[name=csrf-token]").attr("content");
    var xhr = new XMLHttpRequest;
    var data = [];

    data.push("file_name=" + file.name);
    data.push("file_size=" + file.size);
    data.push(csrfParam + "=" + encodeURIComponent(csrfToken));
    

    if (origId) {
      data.push("asset_id=" + origId);
    }

    xhr.open("POST", signUrl);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
    xhr.send(data.join("&"));

    xhr.onload = function () {
      try {
        var data = JSON.parse(xhr.responseText);
        cb(data);
      } catch (e) {
        cb();
       }
    };
  }


  function uploadData(data, cb) {
    var xhr = new XMLHttpRequest;
    var fd = new FormData();
    var fields = data.fields;
    var url = data.url;

    for (var k in fields) {
      fd.append(k, fields[k]);
    }

    fd.append("file", data.file, data.fileName);
    xhr.open("POST", url);
    xhr.send(fd);

    xhr.onload = function () {
      cb();
    };
    xhr.onerror = function (error) {
      cb(I18n.t("errors.upload"));
    };
  }


  var styleOptionRe = /(\d+)x(\d+)/i;

  function parseStyleOption(option) {
    var m = option.match(styleOptionRe)

    return {
      width: m && m[1] || 150,
      height: m && m[2] || 150
    }
  }


  exports.directUpload = function (form, origId, signUrl, cb, cbErr, errKey) {
    var file = $(form).find("input[type=file]").get(0).files[0];

    if (!file) {
      cbErr();
      return;
    }

    fetchUploadSignature(file, origId, signUrl, function (data) {

      function processPost(error) {
        var postData = posts[postPosition];

        if (error) {
          var errObj = {};
          errKey = errKey|| "asset.file";
          errObj[errKey] = [error];

          cbErr(errObj);
          return;
        }
        if (!postData) {
          cb(data.asset_id);
          return;
        }

        postData.fileName = file.name;
        postPosition += 1;
        var styleSize;

        if (postData.style_option) {
          styleSize = parseStyleOption(postData.style_option);

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

      if (!data || data.status === 'error') {
        cbErr(data && data.errors);
        return;
      }

      var posts = data.posts;
      var postPosition = 0;

      processPost();
    });
  }

}(this));

