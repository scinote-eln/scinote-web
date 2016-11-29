(function() {
  'use strict';

  function showNewSampleTypeForm() {
    $('#create-sample-type').on('click', function() {
      $('.new-sample-type-form').slideDown();
    });
  }

  function newSampleTypeFormCancel() {
    $('#remove').on('click', function() {
      $('#name-input').val('');
      $('.new-sample-type-form').slideUp();
    });
  }

  function newSampleTypeFormSubmit() {
    $('#submit').on('click', function() {
      $('#new_sample_type').submit();
    });
  }

  function editSampleTypeForm() {
    $('.edit').on('click', function() {
      var li = $(this).closest('li');
      $.ajax({
        url: li.attr('data-sample-type-edit'),
        success: function(data) {
          $(li).replaceWith($.parseHTML(data.html));

          submitEditSampleTypeForm();
          abortEditSampleTypeAction();

          $('#edit_sample_type_' + data.id)
            .bind('ajax:success', function(ev, data) {
            $(this).closest('li').replaceWith($.parseHTML(data.html));
            editSampleTypeForm();
          });
        }
      });
    });
  }

  function submitEditSampleTypeForm() {
    $('.edit-sample-type').on('click', function() {
      var form = $(this).closest('form');
      form.submit();
    });
  }

  function abortEditSampleTypeAction() {
    $('.abort').on('click', function() {
      var li = $(this).closest('li');
      var href = $(this).attr('data-sample-type-element');
      var id = $(li).attr('data-sample-type-id');

      $.ajax({
        url: href,
        data: { id: id },
        success: function(data) {
          $(li).replaceWith($.parseHTML(data.html));
          editSampleTypeForm();
        }
      });

    });
  }

  function destroySampleType() {
    $('.delete').on('click', function() {
      var li = $(this).closest('li');
      var href = li.attr('data-sample-type-delete');
      var id = $(li).attr('data-sample-type-id');

      $.ajax({
        url: href,
        data: { id: id },
        success: function(data) {
          $('body').append($.parseHTML(data.html));
          $('#modal-delete-sample-type').modal('show',{
            backdrop: true,
            keyboard: false,
          });

          clearModal('#modal-delete-sample-type');
        }
      });
    });
  }

  function clearModal(id) {
    $(id).on('hidden.bs.modal', function() {
      $(id).remove();
    });
  }

  function bindNewSampleTypeAction() {
    $('#new_sample_type').bind('ajax:success', function(ev, data) {
      var li = '<li data-sample-type-id="' + data.id + '"' +
               ' data-sample-type-edit="' + data.edit + '"' +
               ' data-sample-type-delete="' + data.destroy + '">' + data.name +
               '<span class="pull-right"><span class="edit glyphicon ' +
               'glyphicon-pencil"></span><span class="delete glyphicon ' +
               'glyphicon-trash"></span></span></li>';
      $('#name-input').val('');
      $('.new-sample-type-form').slideUp();
      $(li).insertAfter('.new-sample-type-form');
    }).bind('ajax:error', function() {
      alert("error");
    });
  }

  function initSampleTypes() {
      showNewSampleTypeForm();
      newSampleTypeFormCancel();
      newSampleTypeFormSubmit();
      bindNewSampleTypeAction();
      editSampleTypeForm();
      destroySampleType();
  }

  // initialize sample types actions
  initSampleTypes();
})();
