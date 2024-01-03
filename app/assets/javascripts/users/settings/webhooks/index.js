/* global dropdownSelector */

(function() {
  function initDeleteFilterModal() {
    $('.activity-filters-list').on('click', '.delete-filter', function() {
      $('#deleteFilterModal').find('.description b').text(this.dataset.name);
      $('#deleteFilterModal').find('#filter_id').val(this.dataset.id);
      $('#deleteFilterModal').modal('show');
    });
  }

  function initFilterInfoDropdown() {
    $('.info-container').on('show.bs.dropdown', function() {
      var tagsList = $(this).find('.tags-list');
      if (tagsList.is(':empty')) {
        $.get(this.dataset.url, function(data) {
          $.each(data.filter_elements, function(i, element) {
            let tag = $('<span class="filter-info-tag"></span>');
            tag.text(element);
            tagsList.append(tag);
          });
        });
      }
    });
  }
  $('.activity-filters-list').on('ajax:error', '.webhook-form', function(e, data) {
    const { errors } = data.responseJSON;
    // display url errors with data-error-text attribute
    if (errors.url) {
      $(this).find('.url-input-container').addClass('error').attr('data-error-text', `${errors.url.join(', ')}`);
      delete errors.url;
    }
    $(this).renderFormErrors('webhook', errors);
  });

  $('.activity-filters-list').on('click', '.create-webhook', function() {
    let filterElement = $(this).closest('.filter-element');
    filterElement.find('.webhooks-list').collapse('show');
    filterElement.find('.create-webhook-container').removeClass('hidden');
  });

  // clear url form errors
  $('.activity-filters-list').on('click', '.cancel-action, .save-webhook', () => {
    $('.url-input-container').removeClass('error').attr('data-error-text', '');
  });

  $('.activity-filters-list').on('click', '.create-webhook-container .cancel-action', function(e) {
    let webhookContainer = $(this).closest('.create-webhook-container');
    e.preventDefault();
    webhookContainer.addClass('hidden');
    webhookContainer.find('.url-input').val('');
    $('.webhook-form').renderFormErrors('webhook', [], true);
  });

  $('.activity-filters-list').on('click', '.edit-webhook', function(e) {
    let webhookContainer = $(this).closest('.webhook');
    e.preventDefault();
    webhookContainer.find('.view-mode').addClass('hidden');
    webhookContainer.find('.edit-webhook-container').removeClass('hidden');
  });

  $('.activity-filters-list').on('click', '.edit-webhook-container .cancel-action', function(e) {
    let webhookContainer = $(this).closest('.webhook');
    let input = webhookContainer.find('.url-input');
    e.preventDefault();
    input.val(input.data('original-value'));
    webhookContainer.find('.view-mode').removeClass('hidden');
    webhookContainer.find('.edit-webhook-container').addClass('hidden');
    $('.webhook-form').renderFormErrors('webhook', [], true);
  });


  $('.webhook-method-container select').each(function() {
    dropdownSelector.init($(this), {
      singleSelect: true,
      closeOnSelect: true,
      noEmptyOption: true,
      selectAppearance: 'simple',
      disableSearch: true
    });
  });

  initDeleteFilterModal();
  initFilterInfoDropdown();
}());
