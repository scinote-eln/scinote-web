function initShowPassword() {
  $('.fas.fa-eye.show-password').remove();
  $.each($('input[type="password"]'), function(i, e) {
    $(`<i class="fas fa-eye show-password"
          style="
            cursor: pointer;
            z-index: 10;
            top: ${$(e).position().top}px
          "></i>`).prop('title', `show password eye icon for ${e.title}`).insertAfter(e);
    $(e).parent().addClass('right-icon');
  });
}

$(document).on('turbolinks:load', function() {
  initShowPassword();
});

$(document).on('click', '.show-password', function() {
  let $icon = $(this);
  if ($icon.hasClass('fa-eye')) {
    $icon.removeClass('fa-eye').addClass('fa-eye-slash');
    $icon.parent().find('input[type=password]').attr('type', 'text');
  } else {
    $icon.removeClass('fa-eye-slash').addClass('fa-eye');
    $icon.parent().find('input[type=text]').attr('type', 'password');
  }
});
