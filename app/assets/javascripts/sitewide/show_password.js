$(document).on('turbolinks:load', function() {
  $.each($('input[type="password"]'), function(i, e) {
    $('<i class="fas fa-eye show-password" style="cursor: pointer; z-index: 10"></i>').insertAfter(e);
    $(e).parent().addClass('right-icon');
  });
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
