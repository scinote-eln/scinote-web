/* global initInlineEditing PerfectScrollbar */
/* eslint-disable no-restricted-globals, no-alert */
var avatarsModal = (function() {
  var modal = '.modal-user-avatar'

  function initUploadPhotoButton() {
    $(modal).find('.upload-photo').click(() => {
      $(modal).find('#raw_avatar').click()
    })
  }

  function initCropTool() {
    $(modal).find('#raw_avatar').change(function() {
      var reader = new FileReader();
      var inputField = this;
      var croppieContainer;

      $(modal).find('.current-avatar').hide();
      reader.readAsDataURL(inputField.files[0]);
      reader.onload = function() {
        $(modal).find('#new_avatar').val(reader.result);
        var avatarContainer = $(modal).find('.avatar-preview-container')
        avatarContainer.show().children().remove();
        $('<img class="avatar-cropping-preview" src="' + reader.result + '"></img>').appendTo(avatarContainer);
        croppieContainer = $('.avatar-cropping-preview');
        croppieContainer.croppie({ viewport: { width: 150, height: 150, type: 'circle' } });
        avatarContainer.off('update.croppie').on('update.croppie', function() {
          croppieContainer.croppie('result', { type: 'base64', format: 'jpeg', circle: false })
            .then(function(image) {
              $(modal).find('#new_avatar').val(image);
            });
        });
      };
    });
  }

  function initPredefinedAvatars() {
    $(modal).find('.avatar-collection .avatar').click(function() {
      $(modal).find('.avatar-preview-container').hide();
      $(modal).find('.current-avatar').show().find('img')
        .attr('src',$(this).find('img').attr('src'));
      $(modal).find('#new_avatar').val(getBase64Image($(this).find('img')[0]))
    })
  }

  function getBase64Image(img) {
    var canvas = document.createElement("canvas");
    canvas.width = img.width;
    canvas.height = img.height;
    var ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0);
    var dataURL = canvas.toDataURL("image/png");
    return dataURL;
  }

  return {
    init: (mode) => {
      if ($('.modal-user-avatar').length > 0) {
        initUploadPhotoButton()
        initCropTool()
        initPredefinedAvatars()
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  avatarsModal.init();
});
