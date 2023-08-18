function initShowPassword() {
  $('.sn-icon.sn-icon-visibility-show.show-password').remove();
  $.each($('input[type="password"]'), function(i, e) {
    $(`<i class="sn-icon sn-icon-visibility-show show-password"
          style="
            cursor: pointer;
            z-index: 10;
          "></i>`).insertAfter(e);
    $(e).parent().addClass('right-icon');
  });
}

$(document).on('turbolinks:load', function() {
  initShowPassword();
});

$(document).on('click', '.show-password', function() {
  let $icon = $(this);
  if ($icon.hasClass('sn-icon-visibility-show')) {
    $icon.removeClass('sn-icon-visibility-show').addClass('sn-icon-visibility-hide');
    $icon.parent().find('input[type=password]').attr('type', 'text');
  } else {
    $icon.removeClass('sn-icon-visibility-hide').addClass('sn-icon-visibility-show');
    $icon.parent().find('input[type=text]').attr('type', 'password');
  }
});
