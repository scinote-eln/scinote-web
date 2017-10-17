(function() {
  'use strict';

  function showNewSampleTypeGroupForm() {
    $('#create-resource').off();
    $('#create-resource').on('click', function() {
      $('.new-resource-form').slideDown();
      $('#name-input').focus();
    });
  }

  function newSampleTypeFormCancel() {
    $('#remove').off();
    $('#remove').on('click', function(ev) {
      ev.preventDefault();
      $('#name-input').val('');
      $('.new-resource-form').slideUp();
      $('#new_sample_type').clearFormErrors();
      $('#new_sample_group').clearFormErrors();
    });
  }

  function submitEditSampleTypeGroupForm() {
    $('.edit-confirm').off();
    $('.edit-confirm').on('click', function() {
      var form = $(this).closest('form');
      form.submit();
    });
  }

  function abortEditSampleTypeGroupAction() {
    $('.abort').off();
    $('.abort').on('click', function() {
      var li = $(this).closest('li');
      var href = $(this).attr('data-element');
      var id = $(li).attr('data-id');
      $(li).clearFormErrors();
      $.ajax({
        url: href,
        data: { id: id },
        success: function(data) {
          var newLi = $.parseHTML(data.html);
          $(li).replaceWith(newLi);
          editSampleTypeForm();
          destroySampleTypeGroup();
          initSampleColorPicker(newLi);
          appendCarretToColorPickerDropdown();
          editSampleGroupForm();
        }
      });

    });
  }

  function destroySampleTypeGroup() {
    $('.delete').off();
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
        },
        error: function (e) {
          $(li).clearFormErrors();
          var msg = $.parseJSON(e.responseText);

          renderFormError(undefined,
                          $(li).find('.text-edit'),
                          msg.name.toString());
          setTimeout(function() {
            $(li).clearFormErrors();
          }, 5000);
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
    $('#new_sample_type').off();
    $('#new_sample_type').bind('ajax:success', function(ev, data) {
      var li = $.parseHTML(data.html);
      $('#name-input').val('');
      $('.new-resource-form').slideUp();
      $(li).insertAfter('.new-resource-form');
      editSampleTypeForm();
      destroySampleTypeGroup();
      $('#new_sample_type').clearFormErrors();
    }).bind('ajax:error', function(ev, error) {
      $(this).clearFormErrors();
      var msg = $.parseJSON(error.responseText);
      renderFormError(ev,
                      $(this).find('#name-input'),
                      msg.name.toString());
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

  function bindNewSampleGroupAction() {
    $('#new_sample_group').off();
    $('#new_sample_group').bind('ajax:success', function(ev, data) {
      var li = $.parseHTML(data.html);
      $('#name-input').val('');
      $('.new-resource-form').slideUp();
      $(li).insertAfter('.new-resource-form');
      initSampleColorPicker(li);
      appendCarretToColorPickerDropdown();
      editSampleGroupForm();
      destroySampleTypeGroup();
      $('#new_sample_group').clearFormErrors();
    }).bind('ajax:error', function(ev, error) {
      $(this).clearFormErrors();
      var msg = $.parseJSON(error.responseText);
      renderFormError(ev,
                      $(this).find('#name-input'),
                      msg.name.toString());
    });
  }

  function editSampleTypeForm() {
    $('.edit-sample-type').off();
    $('.edit-sample-type').on('click', function() {
      var li = $(this).closest('li');
      $.ajax({
        url: li.attr('data-edit'),
        success: function(data) {
          $(li).replaceWith($.parseHTML(data.html));

          submitEditSampleTypeGroupForm();
          abortEditSampleTypeGroupAction();
          destroySampleTypeGroup();
          $('#edit_sample_type_' + data.id)
            .find('[name="sample_type[name]"]')
            .focus();


          $('#edit_sample_type_' + data.id).off();
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
                            msg.name.toString());
          });
        },
        error: function (e) {
          $(li).clearFormErrors();
          var msg = $.parseJSON(e.responseText);

          renderFormError(undefined,
                          $(li).find('.text-edit'),
                          msg.name.toString());
          setTimeout(function() {
            $(li).clearFormErrors();
          }, 5000);
        }
      });
    });
  }

  function editSampleGroupForm() {
    $('.edit-sample-group').off();
    $('.edit-sample-group').on('click', function() {
      var li = $(this).closest('li');
      $.ajax({
        url: li.attr('data-edit'),
        success: function(data) {
          var newLi = $.parseHTML(data.html);
          $(li).replaceWith(newLi);

          submitEditSampleTypeGroupForm();
          abortEditSampleTypeGroupAction();
          destroySampleTypeGroup();
          initSampleColorPicker(newLi);
          appendCarretToColorPickerDropdown();

          $('#edit_sample_group_' + data.id)
            .find('[name="sample_group[name]"]')
            .focus();

          $('#edit_sample_group_' + data.id).off();
          $('#edit_sample_group_' + data.id)
            .bind('ajax:success', function(ev, data) {
            var newLi = $.parseHTML(data.html);
            $(this).closest('li').replaceWith(newLi);
            editSampleGroupForm();
            destroySampleTypeGroup();
            initSampleColorPicker(newLi);
            appendCarretToColorPickerDropdown();
          }).bind('ajax:error', function(ev, error){
            $(this).clearFormErrors();
            var msg = $.parseJSON(error.responseText);
            renderFormError(ev,
                            $(this).find('#sample_group_name'),
                            msg.name.toString());
          });
        },
        error: function (e) {
          $(li).clearFormErrors();
          var msg = $.parseJSON(e.responseText);

          renderFormError(undefined,
                          $(li).find('.text-edit'),
                          msg.name.toString());
          setTimeout(function() {
            $(li).clearFormErrors();
          }, 5000);
        }
      });
    });
  }

  function editSampleGroupColor() {
    $('.color-picker').on('click', function() {
      var li = $(this).closest('li');
      $.ajax({
        url: li.attr('data-edit'),
        success: function(data) {
        },
        error: function (e) {
          $('.dropdown-colorselector.open').removeClass('open');
          $(li).clearFormErrors();
          var msg = $.parseJSON(e.responseText);

          renderFormError(undefined,
                          $(li).find('.text-edit'),
                          msg.name.toString());
          setTimeout(function() {
            $(li).clearFormErrors();
          }, 5000);
        }
      });
    });
  }

  function initSampleGroupColor() {
    var elements = $('.edit-sample-group-color');
    _.each(elements, function(el) {
      initSampleColorPicker(el);
    });
  }

  function initSampleColorPicker(el) {
    var element;
    if ($(el).is('.edit-sample-group-color')) {
      element = $(el);
    } else {
      element = $(el).find('.edit-sample-group-color');
    }
    var color = $(element).closest('[data-color]').attr('data-color');
    $(element).colorselector('setColor', color);

    // Bind on buttons
    var btns = $(element).closest('.edit_sample_group').find('a.color-btn');
    btns.off();
    btns.on('click', function() {
      var color = $(this).attr('data-value');
      $('select[name="sample_group[color]"]').val(color);

      var form = $(this).closest('form');
      form
      .off('ajax:success ajax:error')
      .on('ajax:success', function() {
      })
      .on('ajax:error', function() {
        form
        .find('select')
        .colorselector(
          'setColor',
          form.closest('[data-color]').attr('data-color')
        );
      });
      form.submit();
    });
  }

/**
 * Opens adding mode when redirected from samples page, when clicking link for
 * adding sample type or group link
 */
  function sampleTypeGroupEditMode() {
    if (getParam('add-mode')) {
      $('#create-resource').click();
    }
  }

  function initSampleTypesGroups() {
    showNewSampleTypeGroupForm();
    newSampleTypeFormCancel();
    bindNewSampleTypeAction();
    editSampleTypeForm();
    destroySampleTypeGroup();
    editSampleGroupForm();
    initSampleGroupColor();
    bindNewSampleGroupAction();
    appendCarretToColorPickerDropdown();
    sampleTypeGroupEditMode();
    editSampleGroupColor();
  }

  // initialize sample types/groups actions
  initSampleTypesGroups();
})();
