/* global dropdownSelector bwipjs zebraPrint I18n*/

(function() {
  'use strict';

  const LABEL_TEMPLATE_SELECTOR = '#label_template_id';
  const LABEL_PRINTER_SELECTOR = '#label_printer_id';
  const ZEBRA_LABEL = 'zebra';
  const FLUICS_LABEL = 'fluics';
  var zebraPrinters;

  function showPrintModal(selector) {
    $(selector).modal('show', {
      backdrop: true,
      keyboard: false
    }).on('hidden.bs.modal', function() {
      $(this).remove();
    });
  }

  function getReposotryRowsIds() {
    return $('[id="repository_row_ids_"]').map(function() {
      return this.value;
    }).get();
  }

  $(document).on('click', '.record-info-link', function(e) {
    var that = $(this);
    $.ajax({
      method: 'GET',
      url: that.attr('href'),
      dataType: 'json'
    }).done(function(xhr, settings, data) {
      if ($('#modal-info-repository-row').length) {
        $('#modal-info-repository-row').find('.modal-body #repository_row-info-table').DataTable().destroy();
        $('#modal-info-repository-row').remove();
        $('.modal-backdrop').remove();
      }
      $('body').append($.parseHTML(data.responseJSON.html));
      $('#modal-info-repository-row').modal('show', {
        backdrop: true,
        keyboard: false
      }).on('hidden.bs.modal', function() {
        $(this).find('.modal-body #repository_row-info-table').DataTable().destroy();
        $(this).remove();
      });

      let barCodeCanvas = bwipjs.toCanvas('bar-code-canvas', {
        bcid: 'qrcode',
        text: $('#modal-info-repository-row #bar-code-canvas').data('id').toString(),
        scale: 3
      });
      $('#modal-info-repository-row #bar-code-image').attr('src', barCodeCanvas.toDataURL('image/png'));


      $('#repository_row-info-table').DataTable({
        dom: 'RBltpi',
        stateSave: false,
        buttons: [],
        processing: true,
        colReorder: {
          fixedColumnsLeft: 1000000 // Disable reordering
        },
        columnDefs: [{
          targets: 0,
          searchable: false,
          orderable: false
        }],
        fnDrawCallback: function(settings, json) {
          animateSpinner(this, false);
        },
        preDrawCallback: function(settings) {
          animateSpinner(this);
        }
      });
    });
    e.preventDefault();
    return false;
  });

  $(document).on('click', '.print-label-button', function() {
    $.ajax({
      method: 'GET',
      url: $(this).data('url'),
      data: { rows: JSON.parse($(this).data('rows')) },
      dataType: 'json'
    }).done(function(xhr, settings, data) {
      $('body').append($.parseHTML(data.responseJSON.html));

      dropdownSelector.init('#modal-print-repository-row-label ' + LABEL_TEMPLATE_SELECTOR, {
        noEmptyOption: true,
        singleSelect: true,
        closeOnSelect: true,
        selectAppearance: 'simple',
        localFilter: function(options) {
          var printerType = JSON.parse($('option:selected', LABEL_PRINTER_SELECTOR).attr('data-params')).type;
          return options.filter(function(option, value) {
            var labelType = JSON.parse($(value).attr('data-params')).type;
            var showLabel = false;
            if (printerType === FLUICS_LABEL) {
              showLabel = [FLUICS_LABEL, ZEBRA_LABEL].some(el => labelType.toLowerCase().includes(el));
            } else if (printerType === ZEBRA_LABEL) {
              showLabel = labelType.toLowerCase().includes(ZEBRA_LABEL);
            }
            return showLabel;
          });
        },
        onSelect: function() {
          $.post(
            $('.print-label-form').data('valid-columns'),
            {
              label_template_id: dropdownSelector.getValues(LABEL_TEMPLATE_SELECTOR),
              repository_row_ids: getReposotryRowsIds()
            }
          )
            // eslint-disable-next-line no-shadow
            .done(function(data) {
              if (data && data.error) {
                $('.label-template-warning').text(data.error);
                dropdownSelector.showWarning(LABEL_TEMPLATE_SELECTOR);
                $('.print-button').val(I18n.t('repository_row.modal_print_label.print_anyway'));
              } else {
                $('.label-template-warning').empty();
                dropdownSelector.hideWarning(LABEL_TEMPLATE_SELECTOR);
                $('.print-button').val(I18n.t('repository_row.modal_print_label.print_label'));
              }
            });
        }
      });

      dropdownSelector.init('#modal-print-repository-row-label ' + LABEL_PRINTER_SELECTOR, {
        noEmptyOption: true,
        singleSelect: true,
        closeOnSelect: true,
        selectAppearance: 'simple',
        onChange: function() {
          var printerType = JSON.parse($('option:selected', LABEL_PRINTER_SELECTOR).attr('data-params')).type;
          var optionsLabel = $(LABEL_TEMPLATE_SELECTOR).find('option');
          var index;
          var value;
          var labelType;
          for (index = 0; index < optionsLabel.length; index += 1) {
            value = optionsLabel[index];
            labelType = JSON.parse($(value).attr('data-params')).type;
            if (labelType.toLowerCase().includes(printerType) && JSON.parse($(value).attr('data-params')).default) {
              dropdownSelector.selectValues(LABEL_TEMPLATE_SELECTOR, $(value).attr('value'));
              break;
            }
          }
        }
      });

      zebraPrinters = zebraPrint.init($('#label_printer_id'), {
        clearSelectorOnFirstDevice: false,
        showModal: function() {
          showPrintModal('#modal-print-repository-row-label');
        },
        noDevices: function() {
          showPrintModal('#modal-print-repository-row-label');
        },
        appendDevice: function(device) {
          $('#label_printer_id').append(`<option data-params='{"type": "zebra", "name": "${device.name}"}'>
            ${device.name} • ${device.status}</option>`);

          if ($('.printers-available').hasClass('hidden')) {
            dropdownSelector.setData(
              '#modal-print-repository-row-label ' + LABEL_PRINTER_SELECTOR,
              [{
                label: `${device.name} • ${device.status}`,
                params: `{"type": "zebra", "name": "${device.name}"}`
              }]
            );
            $('.printers-available').removeClass('hidden');
            $('.no-printers-available').addClass('hidden');
          }
        }
      });

      $('.print-label-form').on('submit', function() {
        var selectedPrinter = JSON.parse($('option:selected', LABEL_PRINTER_SELECTOR).attr('data-params'));
        if (selectedPrinter.type === ZEBRA_LABEL) {
          try {
            zebraPrinters.print(
              $(this).data('zebra-progress'),
              '.label-printing-progress-modal',
              '#modal-print-repository-row-label',
              {
                printer_name: selectedPrinter.name,
                number_of_copies: $('.print-copies-input').val(),
                label_template_id: dropdownSelector.getValues(LABEL_TEMPLATE_SELECTOR),
                repository_row_ids: getReposotryRowsIds()
              }
            );
          } catch (error) {
            return false;
          }
          return false;
        }
        return true;
      });
    });
  });
}());
