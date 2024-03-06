/* global dropdownSelector I18n */
/* eslint-disable no-use-before-define */
(function() {
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
          var newTag;
          initTagsModalBody(data);
          newTag = $('#manage-module-tags-modal .list-group-item').last();
          dropdownSelector.addValue('#module-tags-selector', {
            value: newTag.data('tag-id'),
            label: newTag.data('name'),
            params: {
              color: newTag.data('color')
            }
          }, true);
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

          editDiv.find('.dropdown-colorselector > .dropdown-menu li a')
            .on('click', function() {
              // Change background of the <li>
              const colorSelector = $(this);
              const colorItem = colorSelector.parents('li.list-group-item');
              colorItem.css('background-color', colorSelector.data('value'));
            });

          li.find('div.tag-show').hide();
          editDiv.show();
        });
      manageTagsModalBody.find('.remove-tag-link')
        .on('ajax:success', function(e, data) {
          dropdownSelector.removeValue('#module-tags-selector', this.dataset.tagId, '', true);
          initTagsModalBody(data);
        });
      manageTagsModalBody.find('.delete-tag-form')
        .on('ajax:success', function(e, data) {
          dropdownSelector.removeValue('#module-tags-selector', this.dataset.tagId, '', true);
          initTagsModalBody(data);
        });
      manageTagsModalBody.find('.edit-tag-form')
        .on('ajax:success', function(e, data) {
          var newTag;
          initTagsModalBody(data);
          dropdownSelector.removeValue('#module-tags-selector', this.dataset.tagId, '', true);
          newTag = $('#manage-module-tags-modal .list-group-item[data-tag-id=' + this.dataset.tagId + ']');
          dropdownSelector.addValue('#module-tags-selector', {
            value: newTag.data('tag-id'),
            label: newTag.data('name'),
            params: {
              color: newTag.data('color')
            }
          }, true);
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

      if ($('#experimentTable').length) {
        let tags = $('.tag-show').length;
        $(`#myModuleTags${$('#tags_modal_my_module_id').val()}`).text(
          tags === 0 ? I18n.t('experiments.table.add_tag') : tags
        );
      }

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
    $('#experimentTable, .my-modules-protocols-index, #experiment-canvas')
      .on('click', '.edit-tags-link', function() {
        if($('#tagsModalComponent').length) {
          $('#tagsModalComponent').data('tagsModal').open()
        }
      })
  }

  bindEditTagsAjax();
}());
