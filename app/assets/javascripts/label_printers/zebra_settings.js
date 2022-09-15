/* eslint-disable no-param-reassign */
/* eslint-disable no-undef */
/* global I18n */

(function() {
  var DEVICES = [];

  var getPrinterStatus = function(device) {
    return new Promise((resolve) => {
      new Zebra.Printer(device).getStatus(function(status) {
        device.status = status.getMessage() === 'Ready' ? 'Ready' : 'Offline';
        resolve(device);
      }, function() {
        device.status = 'Offline';
        resolve(device);
      });
    });
  };

  function appendDeviceToHtml(device) {
    if (DEVICES.length === 0) {
      $('.zebra-printers').empty();
    }
    if (!DEVICES.includes(device.name)) {
      $('.zebra-printers').append(`<li>${device.name} <span class="zebra-status-tag ${device.status.toLowerCase()}">
                                     ${device.status}</span></li>`);
      DEVICES.push(device.name);
    }
  }

  function searchZebraPrinters() {
    BrowserPrint.getLocalDevices(function(deviceList) {
      if (deviceList.printer.length !== 0) {
        for (i = 0; i < deviceList.printer.length; i += 1) {
          getPrinterStatus(deviceList.printer[i]).then((device) => {
            appendDeviceToHtml(device);
          });
        }
      } else {
        $('.zebra-printers').empty();
        $('.zebra-printers').append(`<li>${I18n.t('users.settings.account.label_printer.no_printers_available')}</li>`);
      }
    }, () => {
      $('.zebra-printers').empty();
      $('.zebra-printers').append(`<li>${I18n.t('users.settings.account.label_printer.no_printers_available')}</li>`);
    });
  }


  function refreshZebraPrinterList() {
    DEVICES = [];
    $('.zebra-printers').empty();
    $('.zebra-printers').append(`<li>${I18n.t('users.settings.account.label_printer.looking_for_printers')}</li>`);
    searchZebraPrinters();
  }

  $('.zebra-printer-refresh').on('click', function() {
    refreshZebraPrinterList();
  });

  refreshZebraPrinterList();
}());
