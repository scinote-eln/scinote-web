/* global I18n */
/* eslint-disable no-use-before-define */

// Bind ajax for editing descriptions
function bindEditDescriptionAjax() {
  var editDescriptionModal = $('#manage-module-description-modal');
  var editDescriptionModalBody = editDescriptionModal.find('.modal-body');
  var editDescriptionModalSubmitBtn = editDescriptionModal.find('[data-action="submit"]');
  $('.description-link')
    .on('ajax:success', function(ev, data) {
      var descriptionLink = $('.description-refresh');

      // Set modal body & title
      editDescriptionModalBody.html(data.html);
      editDescriptionModal
        .find('#manage-module-description-modal-label')
        .text(data.title);

      editDescriptionModalBody.find('form')
        .on('ajax:success', function(ev2, data2) {
          // Update module's description in the tab
          descriptionLink.html(data2.description_label);

          // Close modal
          editDescriptionModal.modal('hide');
        })
        .on('ajax:error', function() {
          // Display errors if needed
          $(this).renderFormErrors('my_module', data.responseJSON);
        });

      // Show modal
      editDescriptionModal.modal('show');
    })
    .on('ajax:error', function() {
    // TODO
    });

  editDescriptionModalSubmitBtn.on('click', function() {
    // Submit the form inside the modal
    editDescriptionModalBody.find('form').submit();
  });

  editDescriptionModal.on('hidden.bs.modal', function() {
    editDescriptionModalBody.find('form').off('ajax:success ajax:error');
    editDescriptionModalBody.html('');
  });
}

// Bind ajax for editing due dates
function bindEditDueDateAjax() {
  var editDueDateModal = null;
  var editDueDateModalBody = null;
  var editDueDateModalTitle = null;
  var editDueDateModalSubmitBtn = null;

  editDueDateModal = $('#manage-module-due-date-modal');
  editDueDateModalBody = editDueDateModal.find('.modal-body');
  editDueDateModalTitle = editDueDateModal.find('#manage-module-due-date-modal-label');
  editDueDateModalSubmitBtn = editDueDateModal.find("[data-action='submit']");

  $('.due-date-link')
    .on('ajax:success', function(ev, data) {
      var dueDateLink = $('.task-due-date');

      // Load contents
      editDueDateModalBody.html(data.html);
      editDueDateModalTitle.text(data.title);

      // Add listener to form inside modal
      editDueDateModalBody.find('form')
        .on('ajax:success', function(ev2, data2) {
          // Update module's due date
          dueDateLink.html(data2.module_header_due_date_label);

          // Close modal
          editDueDateModal.modal('hide');
        })
        .on('ajax:error', function() {
          // Display errors if needed
          $(this).renderFormErrors('my_module', data.responseJSON);
        });

      // Open modal
      editDueDateModal.modal('show');
    })
    .on('ajax:error', function() {
    // TODO
    });

  editDueDateModalSubmitBtn.on('click', function() {
    // Submit the form inside the modal
    editDueDateModalBody.find('form').submit();
  });

  editDueDateModal.on('hidden.bs.modal', function() {
    editDueDateModalBody.find('form').off('ajax:success ajax:error');
    editDueDateModalBody.html('');
  });
}

// Bind ajax for editing tags
function bindEditTagsAjax() {
  var manageTagsModal = null;
  var manageTagsModalBody = null;

  // Initialize reloading of manage tags modal content after posting new
  // tag.
  function initAddTagForm() {
    manageTagsModalBody.find('.add-tag-form')
      .submit(function() {
        var selectOptions = manageTagsModalBody.find('#new_my_module_tag .dropdown-menu li').length;
        if (selectOptions === 0 && this.id === 'new_my_module_tag') return false;
        return true;
      })
      .on('ajax:success', function(e, data) {
        initTagsModalBody(data);
      });
  }

  // Initialize edit tag & remove tag functionality from my_module links.
  function initTagRowLinks() {
    manageTagsModalBody.find('.edit-tag-link')
      .on('click', function() {
        var $this = $(this);
        var li = $this.parents('li.list-group-item');
        var editDiv = $(li.find('div.tag-edit'));

        // Revert all rows to their original states
        manageTagsModalBody.find('li.list-group-item').each(function() {
          var li2 = $(this);
          li2.css('background-color', li2.data('color'));
          li2.find('.edit-tag-form').clearFormErrors();
          li2.find('input[type=text]').val(li2.data('name'));
        });

        // Hide all other edit divs, show all show divs
        manageTagsModalBody.find('div.tag-edit').hide();
        manageTagsModalBody.find('div.tag-show').show();

        editDiv.find('input[type=text]').val(li.data('name'));
        editDiv.find('.edit-tag-color').colorselector('setColor', li.data('color'));

        li.find('div.tag-show').hide();
        editDiv.show();
      });
    manageTagsModalBody.find('div.tag-edit .dropdown-colorselector > .dropdown-menu li a')
      .on('click', function() {
        // Change background of the <li>
        var $this = $(this);
        var li = $this.parents('li.list-group-item');
        li.css('background-color', $this.data('value'));
      });
    manageTagsModalBody.find('.remove-tag-link')
      .on('ajax:success', function(e, data) {
        initTagsModalBody(data);
      });
    manageTagsModalBody.find('.delete-tag-form')
      .on('ajax:success', function(e, data) {
        initTagsModalBody(data);
      });
    manageTagsModalBody.find('.edit-tag-form')
      .on('ajax:success', function(e, data) {
        initTagsModalBody(data);
      })
      .on('ajax:error', function(e, data) {
        $(this).renderFormErrors('tag', data.responseJSON);
      });
    manageTagsModalBody.find('.cancel-tag-link')
      .on('click', function() {
        var $this = $(this);
        var li = $this.parents('li.list-group-item');

        li.css('background-color', li.data('color'));
        li.find('.edit-tag-form').clearFormErrors();

        li.find('div.tag-edit').hide();
        li.find('div.tag-show').show();
      });
  }

  // Initialize ajax listeners and elements style on modal body. This
  // function must be called when modal body is changed.
  function initTagsModalBody(data) {
    manageTagsModalBody.html(data.html);
    manageTagsModalBody.find('.selectpicker').selectpicker();
    initAddTagForm();
    initTagRowLinks();
  }

  manageTagsModal = $('#manage-module-tags-modal');
  manageTagsModalBody = manageTagsModal.find('.modal-body');

  // Reload tags HTML element when modal is closed
  manageTagsModal.on('hide.bs.modal', function() {
    var tagsEl = $('#module-tags');

    // Load HTML
    $.ajax({
      url: tagsEl.attr('data-module-tags-url'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        var newOptions = $(data.html_module_header).find('option');
        $('#module-tags-selector').find('option').remove();
        $(newOptions).appendTo('#module-tags-selector').change();
      },
      error: function() {
        // TODO
      }
    });
  });

  // Remove modal content when modal window is closed.
  manageTagsModal.on('hidden.bs.modal', function() {
    manageTagsModalBody.html('');
  });
  // initialize my_module tab remote loading
  $('.edit-tags-link')
    .on('ajax:before', function() {
      manageTagsModal.modal('show');
    })
    .on('ajax:success', function(e, data) {
      $('#manage-module-tags-modal-module').text(data.my_module.name);
      initTagsModalBody(data);
    });
}

// Sets callback for completing/uncompleting task
function applyTaskCompletedCallBack() {
  $("[data-action='complete-task'], [data-action='uncomplete-task']")
    .on('click', function() {
      var button = $(this);
      $.ajax({
        url: button.data('link-url'),
        type: 'POST',
        dataType: 'json',
        success: function(data) {
          if (data.completed === true) {
            button.attr('data-action', 'uncomplete-task');
            button.find('.btn')
              .removeClass('btn-primary').addClass('btn-default');
          } else {
            button.attr('data-action', 'complete-task');
            button.find('.btn')
              .removeClass('btn-default').addClass('btn-primary');
          }
          $('.task-due-date').html(data.module_header_due_date_label);
          $('.task-state-label').html(data.module_state_label);
          button.find('button').replaceWith(data.new_btn);
        },
        error: function() {
        }
      });
    });
}

function initTagsSelector() {
  var tagsAjaxQuery = {
    url: $('#module-tags-selector')[0].dataset.searchTagUrl,
    dataType: 'json',
    data: function(params) {
      return {
        query: params.term // search term
      };
    },
    // preparing results
    processResults: function(data) {
      var output = [];
      $.each(data, (index, option) => {
        var el = option;
        el.text = option.name;
        if (option.text.length > 0) {
          output.push(el);
        }
      });
      return {
        results: output
      };
    }
  };

  function tagsCustomResult(state) {
    var result = state.id > 0 ? state.text : state.text + ' <span class="create-new">(' + I18n.t('my_modules.module_header.create_new_tag') + ')</span>';
    result = '<span class="tag-color" style="background: ' + state.color + '"></span><span>' + result + '</span>';
    return $('<div class="add-tags">' + result + '</div>');
  }


  $('#module-tags-selector').select2Multiple({
    ajax: tagsAjaxQuery,
    unlimitedSize: true,
    colorField: 'color',
    templateResult: tagsCustomResult,
    closeOnSelect: true,
    withoutArrow: true,
    dynamicCreation: true,
    dynamicCreationDelimiter: [','],
    placeholderSize: '250px'
  }).on('select2:select', (e) => {
    var params = e.params.data;
    var newTag = null;
    var selectElement = e.target;
    if (params.id > 0) {
      newTag = { my_module_tag: { tag_id: e.params.data.id } };
      $.post($('#module-tags-selector')[0].dataset.updateModuleTagsUrl, newTag)
        .fail(function() {
          $('.module-tags .select2-selection__choice').last().remove();
        });
    } else {
      newTag = {
        tag: {
          name: params.text,
          project_id: selectElement.dataset.projectId,
          color: null
        },
        my_module_id: selectElement.dataset.moduleId,
        simple_creation: true
      };
      $.post(selectElement.dataset.tagsCreateUrl, newTag, function(result) {
        var newOption = '<option data-color="' + result.tag.color + '" value="' + result.tag.id + '">' + result.tag.name + '</option>';
        var selectedValues = $(selectElement).val();
        $(newOption).appendTo($(selectElement));
        $(selectElement).find('option[value=0]').remove();
        selectedValues.splice(-1, 1);
        selectedValues.push(result.tag.id);
        $(selectElement).val(selectedValues).change();
      });
    }
  }).on('select2:unselect', (e)=>{
    var deleteTag = e.params.data.id;
    $(e.target).find('option[value="' + deleteTag + '"]').remove();
    $.post($('#module-tags-selector')[0].dataset.updateModuleTagsUrl + '/' + deleteTag + '/destroy_by_tag_id');
  })
    .prop('disabled', true);

  $(window).click(()=>{
    $('#module-tags-selector').prop('disabled', true);
    $('.select-container .edit-button-container').addClass('hidden');
  });

  $('#module-tags-selector').next().find('.select2-selection, input').click(e => {
    var inputLine = $('#module-tags-selector').next().find('input');
    $('#module-tags-selector').select2('open');
    if ($('#module-tags-selector')[0].dataset.editable !== 'true') return false;
    $('#module-tags-selector').prop('disabled', false);
    $('.select-container .edit-button-container').removeClass('hidden');
    e.stopPropagation();
    inputLine[0].disabled = false;
    inputLine.focus();
    return true;
  });
}

applyTaskCompletedCallBack();
bindEditDueDateAjax();
bindEditDescriptionAjax();
initTagsSelector();
bindEditTagsAjax();
