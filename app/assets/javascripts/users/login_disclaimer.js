(function() {
  const modal = '#loginDisclaimerModal';

  function initDisclaimer(button, form) {
    $(button).on('click', function(e) {
      e.preventDefault();
      $(modal).modal('show');
      $(modal).find('[data-action="submit"]').off('click').one('click', function() {
        $(form).submit();
      });
    });
  }

  initDisclaimer('.log-in-button', '#new_user');
  initDisclaimer('.btn-okta', '#oktaForm');
  initDisclaimer('.btn-azure-ad', '.azureAdForm');
  initDisclaimer('.sign-up-button', '#sign-up-form');
  initDisclaimer('.forgot-password-submit', '#forgot-password-form');
  initDisclaimer('.invitation-submit', '#invitation-form');
}());
