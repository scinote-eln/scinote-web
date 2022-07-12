/* global dropdownSelector bwipjs */

(function() {
  'use strict';

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
      $('#modal-print-repository-row-label').modal('show', {
        backdrop: true,
        keyboard: false
      }).on('hidden.bs.modal', function() {
        $(this).remove();
      });

      dropdownSelector.init('#modal-print-repository-row-label #label_printer_id', {
        noEmptyOption: true,
        singleSelect: true,
        closeOnSelect: true,
        selectAppearance: 'simple'
      });
    });
  });
}());
