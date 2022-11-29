/* eslint-disable no-param-reassign */
/* eslint-disable no-undef */
/* global I18n */
/* eslint-disable no-unused-vars, no-use-before-define */

/* config = {
    clearSelectorOnFirstDevice: boolean, // clear selector options
    noDevices: function(), // what to do if we do not find any device
    appendDevice: function(device), // use device which we find during search
    beforeRefresh: function(), // Action happen before every new device search
  }
*/

var zebraPrint = (function() {
  var devices = [];
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
          device.status = status.getMessage() === I18n.t('label_printers.modal_printing_status.printer_status.ready')
            ? I18n.t('label_printers.modal_printing_status.printer_status.ready')
            : I18n.t('label_printers.modal_printing_status.printer_status.offline');
          resolve(device);
        }, function() {
          device.status = I18n.t('label_printers.modal_printing_status.printer_status.offline');
          resolve(device);
        });
      } catch (error) {
        if (device) {
          device.status = I18n.t('label_printers.modal_printing_status.printer_status.offline');
        } else {
          device = { status: I18n.t('label_printers.modal_printing_status.printer_status.offline') };
        }
        resolve(device);
      }
    });
  };

  function stripPrinterNameHtml(html) {
    let tmp = document.createElement('DIV');
    tmp.innerHTML = html;
    return tmp.textContent || tmp.innerText || '';
  }

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

  function beforeRefresh() {
    if (CONFIG && 'beforeRefresh' in CONFIG) {
      CONFIG.beforeRefresh();
    }
  }

  function clearSelector(clearSelectorOnFirstDevice) {
    if (clearSelectorOnFirstDevice && devices.length === 0) {
      SELECTOR.empty();
    }
  }

  function addNewDevice(device, clearSelectorOnFirstDevice) {
    clearSelector(clearSelectorOnFirstDevice);
    if (!devices.some(function(el) {
      return el.name === device.name;
    })) {
      devices.push(device);
      appendDevice(device);
    }
  }

  function searchZebraPrinters(getStatus) {
    var clearSelectorOnFirstDevice = CONFIG.clearSelectorOnFirstDevice;
    devices = [];
    try {
      beforeRefresh();
      BrowserPrint.getLocalDevices(function(deviceList) {
        if (deviceList && deviceList.printer && deviceList.printer.length !== 0) {
          for (i = 0; i < deviceList.printer.length; i += 1) {
            if (getStatus) {
              getPrinterStatus(deviceList.printer[i]).then((device) => {
                addNewDevice(device, clearSelectorOnFirstDevice);
              });
            } else {
              addNewDevice(deviceList.printer[i], clearSelectorOnFirstDevice);
            }
          }
        } else {
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
    var selectedDevice = devices.filter(function(device) { return device.name === deviceName; });
    return selectedDevice && selectedDevice.length ? selectedDevice[0] : null;
  }

  function updateProgressModalData(progressModal, printerName, printerStatus, printingStatus, numberOfCopies) {
    $(progressModal + ' .title').html(stripPrinterNameHtml(printerName));
    $(progressModal + ' .printer-status').attr('data-status', printerStatus);
    $(progressModal + ' .printer-status').html(I18n.t('label_printers.modal_printing_status.printer_status.'
      + printerStatus));
    $(progressModal + ' .printing-status').attr('data-status', printingStatus);
    $(progressModal + ' .printing-status').html(I18n.t('label_printers.modal_printing_status.printing_status.'
      + printingStatus));
  }

  function print(device, progressModal, numberOfCopies, printerName, labels) {
    var counter = 0;
    try {
      updateProgressModalData(progressModal, printerName, PRINTER_STATUS_READY, PRINTER_STATUS_PRINTING);
      labels.forEach(function(label) {
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
      });
    } catch (error) {
      updateProgressModalData(progressModal, printerName, PRINTER_STATUS_ERROR, PRINTER_STATUS_ERROR);
    }
  }

  function initializeZebraPrinters(selector, config, getStatus) {
    CONFIG = config;
    SELECTOR = selector;
    searchZebraPrinters(getStatus);
  }

  return {
    init: function(selector, config, getStatus) {
      initializeZebraPrinters(selector, config, getStatus);
      return this;
    },
    refreshList: function() {
      searchZebraPrinters(true);
    },

    /*
      printData: {
        printer_name: string,
        number_of_copies: int,
        label_template_id: int,
        repository_row_ids: array[]
      }
    */
    print: function(modalUrl, progressModal, printModal, printData) {
      var modal = $(progressModal);
      $.ajax({
        method: 'GET',
        url: modalUrl,
        data: printData,
        dataType: 'json'
      }).done(function(xhr, settings, dataZebra) {
        $(printModal).modal('hide');

        if (modal.length) {
          modal.replaceWith(dataZebra.responseJSON.html);
        } else {
          $('body').append($(dataZebra.responseJSON.html));
        }

        updateProgressModalData(progressModal, printData.printer_name, PRINTER_STATUS_READY, PRINTER_STATUS_PRINTING);
        device = findDevice(printData.printer_name);
        new Zebra.Printer(device).isPrinterReady(function() {
          $(document).on('click', progressModal, function() {
            $(this).closest(progressModal).remove();
          });

          print(
            device, progressModal, printData.number_of_copies,
            printData.printer_name, dataZebra.responseJSON.labels
          );
        }, function() {
          updateProgressModalData(progressModal, printData.printer_name, PRINTER_STATUS_ERROR, PRINTER_STATUS_ERROR);
        });
      });
    }
  };
}());
