/* eslint-disable no-param-reassign eslint-disable no-undef */
/* global I18n zebraPrint */

(function() {
  var zebraPrinter;

  function initZebraPrinterList() {
    var zebraContainer = $('.zebra-printers');
    zebraPrinter = zebraPrint.init(
      zebraContainer,
      {
        clearSelectorOnFirstDevice: true,
        noDevices: function() {
          zebraContainer.empty();
          zebraContainer.append(`<li>
            ${I18n.t('users.settings.account.label_printer.no_printers_available')}</li>`);
        },
        appendDevice: function(device) {
          zebraContainer.append(`<li>${device.name} <span class="zebra-status-tag ${device.status.toLowerCase()}">
                                     ${device.status}</span></li>`);
        },
        beforeRefresh: function() {
          zebraContainer.empty();
          zebraContainer.append(`
          <li class="searching-printers">
            <img src="/images/medium/loading.svg"></img>
            ${I18n.t('users.settings.account.label_printer.looking_for_printers')}
          </li>`);
        }
      },
      true
    );
  }

  $('.zebra-printer-refresh').on('click', function() {
    zebraPrinter.refreshList();
  });

  initZebraPrinterList();
}());
