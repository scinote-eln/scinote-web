/* global bwipjs PrintModalComponent RepositoryDatatable */

(function() {
  'use strict';

  $(document).on('click', '.record-info-link', function(e) {
    var that = $(this);
    let params = {};
    if ($('.my-modules-protocols-index').length) {
      params.my_module_id = $('.my-modules-protocols-index').data('task-id');
    }
    $.ajax({
      method: 'GET',
      url: that.attr('href'),
      data: params,
      dataType: 'json'
    }).done(function(xhr, settings, data) {
      if ($('#modal-info-repository-row').length) {
        $('#modal-info-repository-row').find('.modal-body #repository_row-info-table').DataTable().destroy();
        $('#modal-info-repository-row').remove();
        $('.modal-backdrop').remove();
      }
      $('body').append($.parseHTML(data.responseJSON.html));
      $('[data-toggle="tooltip"]').tooltip();
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
    var selectedRows = $(this).data('rows');
    if (typeof PrintModalComponent !== 'undefined') {
      PrintModalComponent.showModal = true;
      if (selectedRows.length) {
        $('#modal-info-repository-row').modal('hide');
        PrintModalComponent.row_ids = selectedRows;
      } else {
        PrintModalComponent.row_ids = RepositoryDatatable.selectedRows();
      }
    }
  });
}());
