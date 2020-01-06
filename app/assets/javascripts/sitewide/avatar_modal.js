
/* eslint-disable no-restricted-globals, no-alert */
var avatarsModal = (function() {
  var modal = '.modal-user-avatar';

  function initUploadPhotoButton() {
    $(modal).find('.upload-photo').click(() => {
      $(modal).find('#raw_avatar').click();
    });
  }

  function getBase64Image(img) {
    var ctx;
    var dataURL;
    var canvas = document.createElement('canvas');
    canvas.width = 200;
    canvas.height = 200;
    ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0);
    dataURL = canvas.toDataURL('image/png');
    return dataURL;
  }

  function initCropTool() {
    $(modal).find('#raw_avatar').change(function() {
      var reader = new FileReader();
      var inputField = this;
      var croppieContainer;

      $(modal).find('.current-avatar').hide();
      reader.readAsDataURL(inputField.files[0]);
      reader.onload = function() {
        var avatarContainer = $(modal).find('.avatar-preview-container');
        $(modal).find('.save-button').attr('disabled', false);
        $(modal).find('#new_avatar').val(reader.result);

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
      $(modal).find('.save-button').attr('disabled', false);
      $(modal).find('#raw_avatar')[0].value = null;
      $(modal).find('.avatar-preview-container').hide();
      $(modal).find('.current-avatar').show().find('img')
        .attr('src', $(this).find('img').attr('src'));
      $(modal).find('#new_avatar').val(getBase64Image($(this).find('img')[0]));
    });
  }

  function initUpdateButton() {
    $(modal).find('.save-button').click(function() {
      if ($(this).is('[disabled=disabled]')) return;

      $(this).attr('disabled', true);
      $.ajax({
        url: $(modal).data('update-url'),
        type: 'PUT',
        data: {
          'user[avatar]': $(modal).find('#new_avatar').val(),
          'user[change_avatar]': true
        },
        dataType: 'json',
        success: () => {
          location.reload();
        },
        error: () => {
          $(this).attr('disabled', false);
        }
      });
    });
  }

  return {
    init: () => {
      if ($(modal).length > 0) {
        initUploadPhotoButton();
        initCropTool();
        initPredefinedAvatars();
        initUpdateButton();
        $('.user-settings-edit-avatar img, .avatar-container').click(() => {
          $(modal).modal('show');
        });
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  avatarsModal.init();
});
