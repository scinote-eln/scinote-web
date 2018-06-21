(function() {
  'use strict';
  // handles CSV upload for samples import
  function postSamplesCSV() {
    var form = $('form#form-samples-file');
    var submitBtn = form.find('input[type="submit"]');
    submitBtn.on('click', function(event) {
      event.preventDefault();
      event.stopPropagation();
      var data = new FormData();
      data.append('file', document.getElementById('file').files[0]);
      $.ajax({
        type: 'POST',
        url: form.attr('action'),
        data: data,
        success: _handleSuccessfulSubmit,
        error: _handleErrorSubmit,
        processData: false,
        contentType: false,
      });
    });
  }

  function _handleSuccessfulSubmit(data) {
    $('#modal-parse-samples').html(data.html);
    $('#modal-import-samples').modal('hide');
    $('#modal-parse-samples').modal('show');
  }

  function _handleErrorSubmit(XHR) {
    var formGroup = $('form#form-samples-file').find('.form-group');
    formGroup.addClass('has-error');
    formGroup.find('.help-block').remove();
    formGroup.append('<span class="help-block">' +
                     XHR.responseJSON.message + '</span>');
  }

  $(document).ready(postSamplesCSV);
})()


// Create import samples ajax
$("#modal-import-samples").on("show.bs.modal", function(event) {
    formGroup = $(this).find(".form-group");
    formGroup.removeClass("has-error");
    formGroup.find(".help-block").remove();
});

$('.sample-assign-group > .btn').click(function() {
  $('.btn-group > .btn').removeClass('active btn-primary');
  $('.btn-group > .btn').addClass('btn-default');
  $(this).addClass('active btn-primary');
});

// Fetch samples data and updates the select options fields for
// sample group and sample type column
function updateSamplesTypesandGroups() {
  changeToEditMode();
  updateButtons();

  $.ajax({
    url: $("table#samples").data("new-sample"),
    type: "GET",
    dataType: "json",
    success: function (data) {
      $("select[name=sample_group_id]").each(function(){
        var sample_group = $(this).val();
        var selectGroup = createSampleGroupSelect(data.sample_groups, sample_group);
        var gtd = $(this).parent("td");
        gtd.html(selectGroup[0]);
      });
      $("select[name=sample_type_id]").each(function(){
        var sample_type = $(this).val();
        var selectType = createSampleTypeSelect(data.sample_types, sample_type);
        var ttd = $(this).parent("td");
        ttd.html(selectType[0]);
      });

      $("select[name=sample_group_id]").selectpicker();
      $("select[name=sample_type_id]").selectpicker();
    },
    error: function (e, eData, status, xhr) {
      if (e.status == 403)
        showAlertMessage(I18n.t("samples.js.permission_error"));
        changeToViewMode();
        updateButtons();
      }
    });
}
