$(document).on('turbolinks:load', function() {
  $(document).on('click', '#twoFactorAuthenticationDisable', function() {
    $('#twoFactorAuthenticationModal').modal('show');
    $('#password').focus();
  });

  $(document).on('click', '#twoFactorAuthenticationEnable', function() {
    // close all other modals
    $('.modal').modal('hide');

    $.get(this.dataset.qrCodeUrl, function(result) {
      $('#twoFactorAuthenticationModal .qr-code').html(result.qr_code);
      $('#twoFactorAuthenticationModal').find('[href="#2fa-step-1"]').tab('show');
      $('#twoFactorAuthenticationModal').modal('show');
      $('#twoFactorAuthenticationModal').find('.submit-code-field').removeClass('error').find('#submit_code')
        .val('');
    });
  });

  $('#twoFactorAuthenticationModal .2fa-enable-form').on('ajax:error', function(e, data) {
    $(this).find('.submit-code-field').addClass('error').attr('data-error-text', data.responseJSON.error);
  }).on('ajax:success', function(e, data) {
    // Enabling 2FA re-authenticates the session, which rotates the CSRF token server-side.
    // Refresh the token client-side so subsequent requests on this page don't 422.
    if (data.csrf_token) {
      var metaTag = document.querySelector('meta[name="csrf-token"]');
      if (metaTag) { metaTag.setAttribute('content', data.csrf_token); }
      document.querySelectorAll('input[type="hidden"][name="authenticity_token"]')
        .forEach(function(input) { input.value = data.csrf_token; });
    }
    var blob = new Blob([data.recovery_codes.join('\r\n')], { type: 'text/plain;charset=utf-8' });
    $('#twoFactorAuthenticationModal').find('.recovery-codes').html(data.recovery_codes.join('<br>'));
    $('#twoFactorAuthenticationModal').find('[href="#2fa-step-4"]').tab('show');
    $('.download-recovery-codes').attr('href', window.URL.createObjectURL(blob));
    $('#twoFactorAuthenticationModal').one('hide.bs.modal', function() {
      window.location.reload();
    });
  });

  $('#twoFactorAuthenticationModal .2fa-disable-form').on('ajax:error', function(e, data) {
    $(this).find('.password-field').addClass('error').attr('data-error-text', data.responseJSON.error);
  });

  $('#twoFactorAuthenticationModal').on('click', '.btn-next-step', function() {
    setTimeout(() => {
      $('#submit_code').focus();
    }, 500);
    $('#twoFactorAuthenticationModal').find(`[href="${$(this).data('step')}"]`).tab('show');
  });
});
