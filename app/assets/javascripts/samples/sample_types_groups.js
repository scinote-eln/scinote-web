(function() {
  'use strict';

  function showNewSampleTypeGroupForm() {
    $('#create-resource').on('click', function() {
      $('.new-resource-form').slideDown();
    });
  }

  function newSampleTypeFormCancel() {
    $('#remove').on('click', function() {
      $('#name-input').val('');
      $('.new-resource-form').slideUp();
    });
  }

  function newSampleTypeGroupFormSubmit() {
    $('#submit').on('click', function() {
      var form = $(this).closest('form');
      form.submit();
    });
  }

  function submitEditSampleTypeGroupForm(button) {
    $('.edit-confirm').on('click', function() {
      var form = $(this).closest('form');
      form.submit();
    });
  }

  function abortEditSampleTypeGroupAction() {
    $('.abort').on('click', function() {
      var li = $(this).closest('li');
      var href = $(this).attr('data-element');
      var id = $(li).attr('data-id');

      $.ajax({
        url: href,
        data: { id: id },
        success: function(data) {
          $(li).replaceWith($.parseHTML(data.html));
          editSampleTypeForm();
          destroySampleTypeGroup();
          initSampleGroupColor();
          appendCarretToColorPickerDropdown();
        }
      });

    });
  }

  function destroySampleTypeGroup() {
    $('.delete').on('click', function() {
      var li = $(this).closest('li');
      var href = li.attr('data-delete');
      var id = $(li).attr('data-id');

      $.ajax({
        url: href,
        data: { id: id },
        success: function(data) {
          $('body').append($.parseHTML(data.html));
          $('#modal-delete').modal('show',{
            backdrop: true,
            keyboard: false,
          });

          clearModal('#modal-delete');
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
      var li = $.parseHTML(data.html);
      $('#name-input').val('');
      $('.new-resource-form').slideUp();
      $(li).insertAfter('.new-resource-form');
      editSampleTypeForm();
      destroySampleTypeGroup();
    }).bind('ajax:error', function(ev, error) {
      $(this).clearFormErrors();
      var msg = $.parseJSON(error.responseText);
      renderFormError(ev,
                      $(this).find('#name-input'),
                      Object.keys(msg)[0] + ' '+ msg.name.toString());
    });
  }

  function appendCarretToColorPickerDropdown() {
    $(document).ready(function() {
      _.each($('.btn-colorselector'), function(el){
        if(!$(el).next().is('span.caret')) {
          $(el).after($.parseHTML('<span class="caret"></span>'));
        }
      });
    });
  }

  function editSampleGroupColor() {
    $(document).ready(function() {
      $('.color-btn').on('click', function() {
        var color = $(this).attr('data-value');
        var form = $(this).closest('form');
        $('select[name="sample_group[color]"]')
          .val(color);
        form.submit();
      });
    });
  }

  function bindNewSampleGroupAction() {
    $('#new_sample_group').bind('ajax:success', function(ev, data) {
      var li = $.parseHTML(data.html);
      $('#name-input').val('');
      $('.new-resource-form').slideUp();
      $(li).insertAfter('.new-resource-form');
      initSampleGroupColor();
      appendCarretToColorPickerDropdown();
      editSampleGroupColor();
      editSampleGroupForm();
    }).bind('ajax:error', function(ev, error) {
      $(this).clearFormErrors();
      var msg = $.parseJSON(error.responseText);
      renderFormError(ev,
                      $(this).find('#name-input'),
                      Object.keys(msg)[0] + ' '+ msg.name.toString());
    });
  }

  function editSampleTypeForm() {
    $('.edit').on('click', function() {
      var li = $(this).closest('li');
      $.ajax({
        url: li.attr('data-edit'),
        success: function(data) {
          $(li).replaceWith($.parseHTML(data.html));

          submitEditSampleTypeGroupForm();
          abortEditSampleTypeGroupAction();
          destroySampleTypeGroup();

          $('#edit_sample_type_' + data.id)
            .bind('ajax:success', function(ev, data) {
            $(this).closest('li').replaceWith($.parseHTML(data.html));
            editSampleTypeForm();
            destroySampleTypeGroup();
          }).bind('ajax:error', function(ev, error){
            $(this).clearFormErrors();
            var msg = $.parseJSON(error.responseText);
            renderFormError(ev,
                            $(this).find('#sample_type_name'),
                            Object.keys(msg)[0] + ' '+ msg.name.toString());
          });
        }
      });
    });
  }

  function editSampleGroupForm() {
    $('.edit').on('click', function() {
      var li = $(this).closest('li');
      $.ajax({
        url: li.attr('data-edit'),
        success: function(data) {
          $(li).replaceWith($.parseHTML(data.html));

          submitEditSampleTypeGroupForm();
          abortEditSampleTypeGroupAction();
          destroySampleTypeGroup();
          initSampleGroupColor();
          appendCarretToColorPickerDropdown();
          editSampleGroupColor();

          $('#edit_sample_group_' + data.id)
            .bind('ajax:success', function(ev, data) {
            $(this).closest('li').replaceWith($.parseHTML(data.html));
            editSampleGroupForm();
            destroySampleTypeGroup();
            initSampleGroupColor();
            appendCarretToColorPickerDropdown();
            editSampleGroupColor();
          }).bind('ajax:error', function(ev, error){
            $(this).clearFormErrors();
            var msg = $.parseJSON(error.responseText);
            renderFormError(ev,
                            $(this).find('#sample_group_name'),
                            Object.keys(msg)[0] + ' '+ msg.name.toString());
          });
        }
      });
    });
  }

  function initSampleGroupColor() {
    var elements = $('.edit-sample-group-color');
    _.each(elements, function(el) {
      var color = $(el).closest('[data-color]')
                       .attr('data-color');
      $(el).colorselector('setColor', color);
    });
  }

  function initSampleTypesGroups() {
    showNewSampleTypeGroupForm();
    newSampleTypeFormCancel();
    newSampleTypeGroupFormSubmit();
    bindNewSampleTypeAction();
    editSampleTypeForm();
    destroySampleTypeGroup();
    editSampleGroupForm();
    editSampleGroupColor();
    initSampleGroupColor();
    bindNewSampleGroupAction();
    appendCarretToColorPickerDropdown();
  }

  // initialize sample types/groups actions
  initSampleTypesGroups();
})();
