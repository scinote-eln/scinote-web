/* eslint-disable no-param-reassign */
/* eslint-disable no-undef */
/* global */
/* eslint-disable no-unused-vars, no-use-before-define */

/* config = {
    clearSelectorOnFirstDevice: boolean, // clear selector options
    noDevices: function(), // what to do if we do not find any device
    appendDevice: function(device), // use device which we find during search
    beforeRefresh: function(), // Action happen before every new device search
  }
*/

var zebraPrint = (function() {
  var DEVICES = [];
  var CONFIG = {};
  var SELECTOR = '';
  const PRINTER_STATUS_READY = 'ready';
  const PRINTER_STATUS_ERROR = 'error';
  const PRINTER_STATUS_PRINTING = 'printing';
  const PRINTER_STATUS_DONE = 'done';

  var getPrinterStatus = function(device) {
    return new Promise((resolve) => {
      try {
        new Zebra.Printer(device).getStatus(function(status) {
          device.status = status.getMessage() === 'Ready' ? 'Ready' : 'Offline';
          resolve(device);
        }, function() {
          device.status = 'Offline';
          resolve(device);
        });
      } catch (error) {
        if (device) {
          device.status = 'Offline';
        } else {
          device = { status: 'Offline' };
        }
        resolve(device);
      }
    });
  };

  function noDevices() {
    if (CONFIG && 'noDevices' in CONFIG) {
      CONFIG.noDevices();
    }
  }

  function appendDevice(device) {
    if (CONFIG && 'appendDevice' in CONFIG) {
      CONFIG.appendDevice(device);
    }
  }

  function showModal() {
    if (CONFIG && 'showModal' in CONFIG) {
      CONFIG.showModal();
    }
  }

  function beforeRefresh() {
    if (CONFIG && 'beforeRefresh' in CONFIG) {
      CONFIG.beforeRefresh();
    }
  }

  function clearSelector(clearSelectorOnFirstDevice) {
    if (clearSelectorOnFirstDevice && DEVICES.length === 0) {
      SELECTOR.empty();
    }
  }

  function addNewDevice(device, clearSelectorOnFirstDevice) {
    clearSelector(clearSelectorOnFirstDevice);
    if (DEVICES.length === 0) showModal();
    if (!DEVICES.some(function(el) {
      return el.name === device.name;
    })) {
      DEVICES.push(device);
      appendDevice(device);
    }
  }

  function searchZebraPrinters() {
    var clearSelectorOnFirstDevice = CONFIG.clearSelectorOnFirstDevice;
    DEVICES = [];
    try {
      beforeRefresh();
      BrowserPrint.getLocalDevices(function(deviceList) {
        if (deviceList.printer && deviceList.printer.length !== 0) {
          for (i = 0; i < deviceList.printer.length; i += 1) {
            getPrinterStatus(deviceList.printer[i]).then((device) => {
              addNewDevice(device, clearSelectorOnFirstDevice);
            });
          }
        } else {
          showModal();
          noDevices();
        }
      }, () => {
        noDevices();
      });
    } catch (error) {
      noDevices();
    }
  }

  function findDevice(deviceName) {
    var selectedDevice = DEVICES.filter(function(device) { return device.name === deviceName; });
    return selectedDevice && selectedDevice.length ? selectedDevice[0] : null;
  }

  function updateProgressModalData(progressModal, printerName, printerStatus, printingStatus, numberOfCopies) {
    $(progressModal + ' .title').html(printerName);
    $(progressModal + ' .printer-status').attr('data-status', printerStatus);
    $(progressModal + ' .printer-status').html(I18n.t('label_printers.modal_printing_status.printer_status.'
      + printerStatus));
    $(progressModal + ' .printing-status').attr('data-status', printingStatus);
    $(progressModal + ' .printing-status').html(I18n.t('label_printers.modal_printing_status.printing_status.'
      + printingStatus));
  }

  function print(device, progressModal, numberOfCopies, printerName) {
    var counter = 0;
    var label = '^XA ^FX First section with bar code. ^BY5,2,270 ^FO100,50^BC^FD12345678^FS^XZ';
    try {
      updateProgressModalData(progressModal, printerName, PRINTER_STATUS_READY, PRINTER_STATUS_PRINTING);
      for (counter = 0; counter < numberOfCopies; counter += 1) {
        if (counter + 1 === parseInt(numberOfCopies, 10)) {
          device.sendThenRead(
            label,
            () => {
              updateProgressModalData(progressModal, printerName, PRINTER_STATUS_READY, PRINTER_STATUS_DONE);
            },
            (error)=> {
              updateProgressModalData(progressModal, printerName, PRINTER_STATUS_ERROR, PRINTER_STATUS_ERROR);
            }
          );
        } else {
          device.send(label, ()=>{}, (error)=> {
            updateProgressModalData(progressModal, printerName, PRINTER_STATUS_ERROR, PRINTER_STATUS_ERROR);
          });
        }
      }
    } catch (error) {
      updateProgressModalData(progressModal, printerName, PRINTER_STATUS_ERROR, PRINTER_STATUS_ERROR);
    }
  }

  function initializeZebraPrinters(selector, config) {
    CONFIG = config;
    SELECTOR = selector;
    searchZebraPrinters();
  }

  return {
    init: function(selector, config) {
      initializeZebraPrinters(selector, config);
      return this;
    },
    refreshList: function() {
      searchZebraPrinters();
    },
    print: function(modalUrl, progressModal, printModal, printerName, numberOfCopies) {
      var modal = $(progressModal);
      device = findDevice(printerName);
      new Zebra.Printer(device).isPrinterReady(function() {
        $.ajax({
          method: 'GET',
          url: modalUrl,
          dataType: 'json'
        }).done(function(xhr, settings, dataZebra) {
          if (modal.length) {
            modal.replaceWith(dataZebra.responseJSON.html);
          } else {
            $('body').append($(dataZebra.responseJSON.html));
          }

          $(document).on('click', progressModal, function() {
            $(this).closest(progressModal).remove();
          });

          $(printModal).modal('hide');
          print(device, progressModal, numberOfCopies, printerName);
        });
      }, function() {
        updateProgressModalData(progressModal, printerName, PRINTER_STATUS_ERROR, PRINTER_STATUS_ERROR);
      });
    }
  };
}());
