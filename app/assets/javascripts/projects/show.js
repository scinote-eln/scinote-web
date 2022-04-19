/* global animateSpinner filterDropdown Sidebar Turbolinks HelperModule InfiniteScroll GLOBAL_CONSTANTS */
/* eslint-disable no-use-before-define */
(function() {
  const PERMISSIONS = ['editable', 'archivable', 'restorable', 'moveable', 'duplicable'];
  const pageSize = GLOBAL_CONSTANTS.DEFAULT_ELEMENTS_PER_PAGE;
  var cardsWrapper = '#cardsWrapper';
  var experimentsPage = '#projectShowWrapper';

  var selectedExperiments = [];

  let experimentsCurrentSort;
  let experimentsViewSearch;
  let startedOnFromFilter;
  let startedOnToFilter;
  let modifiedOnFromFilter;
  let modifiedOnToFilter;
  let archivedOnFromFilter;
  let archivedOnToFilter;


  function checkActionPermission(permission) {
    return selectedExperiments.every(function(experimentId) {
      return $(`.experiment-card[data-id="${experimentId}"]`).data(permission);
    });
  }

  function updateExperimentsToolbar() {
    let experimentsToolbar = $('#projectShowToolbar');
    let toolbarVisible = false;

    if (selectedExperiments.length === 0) {
      experimentsToolbar.find('.single-object-action, .multiple-object-action').addClass('hidden');
    }

    if (selectedExperiments.length === 1) {
      experimentsToolbar.find('.single-object-action, .multiple-object-action').removeClass('hidden');
    } else if (selectedExperiments.length > 1) {
      experimentsToolbar.find('.single-object-action').addClass('hidden');
      experimentsToolbar.find('.multiple-object-action').removeClass('hidden');
    }
    PERMISSIONS.forEach((permission) => {
      if (!checkActionPermission(permission)) {
        experimentsToolbar.find(`.btn[data-for="${permission}"]`).addClass('hidden');
      }
    });

    $.each($('#projectShowToolbar').find('.btn'), (i, btn) => {
      if (window.getComputedStyle(btn).display !== 'none') {
        toolbarVisible = true;
      }
    });
    $(experimentsPage).attr('data-toolbar-visible', toolbarVisible);
  }

  function initProjectsViewModeSwitch() {
    $(experimentsPage)
      .on('ajax:success', '.change-experiments-view-type-form', function(ev, data) {
        $(cardsWrapper).removeClass('list').addClass(data.cards_view_type_class);
        $(experimentsPage).find('.cards-switch .button-to').removeClass('selected');
        $(ev.target).find('.button-to').addClass('selected');
        $(ev.target).parents('.dropdown.view-switch').removeClass('open');
      })
      .on('ajax:error', '.change-projects-view-type-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
      });

    $(experimentsPage).on('click', '.archive-switch', function() {
      Turbolinks.visit($(this).data('url'));
    });
  }

  function loadPlaceHolder() {
    let palceholder = '';
    $.each(Array(pageSize), function() {
      palceholder += $('#experimentPlaceholder').html();
    });
    $(palceholder).insertAfter($(cardsWrapper).find('.table-header'));
  }

  function loadCardsView() {
    var requestParams = {
      view_mode: $(experimentsPage).data('view-mode'),
      sort: experimentsCurrentSort,
      search: experimentsViewSearch,
      created_on_from: startedOnFromFilter,
      created_on_to: startedOnToFilter,
      updated_on_from: modifiedOnFromFilter,
      updated_on_to: modifiedOnToFilter,
      archived_on_from: archivedOnFromFilter,
      archived_on_to: archivedOnToFilter
    };
    var viewContainer = $(cardsWrapper);
    var cardsUrl = viewContainer.data('experiments-cards-url');

    loadPlaceHolder();
    $.ajax({
      url: cardsUrl,
      type: 'GET',
      dataType: 'json',
      data: requestParams,
      success: function(data) {
        viewContainer.find('.card, .no-results-container').remove();
        viewContainer.removeClass('no-results');
        viewContainer.append(data.cards_html);
        if (viewContainer.find('.no-results-container').length) {
          viewContainer.addClass('no-results');
        }
        selectedExperiments.length = 0;
        updateExperimentsToolbar();
        loadExperimentWorkflowImages();

        InfiniteScroll.init(cardsWrapper, {
          url: cardsUrl,
          eventTarget: window,
          placeholderTemplate: '#experimentPlaceholder',
          endOfListTemplate: '#experimentEndOfList',
          pageSize: pageSize,
          customResponse: (response) => {
            $(response.cards_html).appendTo(cardsWrapper);
          },
          customParams: (params) => {
            return { ...params, ...requestParams };
          }
        });
      },
      error: function() {
        viewContainer.html('Error loading project list');
      }
    });
  }

  function refreshCurrentView() {
    loadCardsView();
    Sidebar.reload({
      sort: experimentsCurrentSort,
      view_mode: $(experimentsPage).data('view-mode')
    });
  }

  function selectDate($field) {
    var datePicker = $field.data('DateTimePicker');
    if (datePicker && datePicker.date()) {
      return datePicker.date()._d.toUTCString();
    }
    return null;
  }

  function initExperimentsFilters() {
    var $filterDropdown = filterDropdown.init();

    let $experimentsFilter = $('.experiments-filters');
    let $startedOnFromFilter = $('.started-on-filter .from-date', $experimentsFilter);
    let $startedOnToFilter = $('.started-on-filter .to-date', $experimentsFilter);
    let $modifiedOnFromFilter = $('.modified-on-filter .from-date', $experimentsFilter);
    let $modifiedOnToFilter = $('.modified-on-filter .to-date', $experimentsFilter);
    let $archivedOnFromFilter = $('.archived-on-filter .from-date', $experimentsFilter);
    let $archivedOnToFilter = $('.archived-on-filter .to-date', $experimentsFilter);
    let $textFilter = $('#textSearchFilterInput', $experimentsFilter);

    function appliedFiltersMark() {
      let filtersEnabled = experimentsViewSearch
        || startedOnFromFilter
        || startedOnToFilter
        || modifiedOnFromFilter
        || modifiedOnToFilter
        || archivedOnFromFilter
        || archivedOnToFilter;
      filterDropdown.toggleFilterMark($filterDropdown, filtersEnabled);
    }

    $filterDropdown.on('filter:apply', function() {
      startedOnFromFilter = selectDate($startedOnFromFilter);
      startedOnToFilter = selectDate($startedOnToFilter);
      modifiedOnFromFilter = selectDate($modifiedOnFromFilter);
      modifiedOnToFilter = selectDate($modifiedOnToFilter);
      archivedOnFromFilter = selectDate($archivedOnFromFilter);
      archivedOnToFilter = selectDate($archivedOnToFilter);
      experimentsViewSearch = $textFilter.val();
      appliedFiltersMark();
      refreshCurrentView();
    });

    // Clear filters
    $filterDropdown.on('filter:clear', function() {
      if ($startedOnFromFilter.data('DateTimePicker')) $startedOnFromFilter.data('DateTimePicker').clear();
      if ($startedOnToFilter.data('DateTimePicker')) $startedOnToFilter.data('DateTimePicker').clear();
      if ($modifiedOnFromFilter.data('DateTimePicker')) $modifiedOnFromFilter.data('DateTimePicker').clear();
      if ($modifiedOnToFilter.data('DateTimePicker')) $modifiedOnToFilter.data('DateTimePicker').clear();
      if ($archivedOnFromFilter.data('DateTimePicker')) $archivedOnFromFilter.data('DateTimePicker').clear();
      if ($archivedOnToFilter.data('DateTimePicker')) $archivedOnToFilter.data('DateTimePicker').clear();
      $textFilter.val('');
    });
  }

  function initSorting() {
    $('#sortMenuDropdown a').click(function() {
      if (experimentsCurrentSort !== $(this).data('sort')) {
        $('#sortMenuDropdown a').removeClass('selected');
        experimentsCurrentSort = $(this).data('sort');
        refreshCurrentView();
        $(this).addClass('selected');
        $('#sortMenu').dropdown('toggle');
      }
    });
  }

  function initExperimentsSelector() {
    $(cardsWrapper).on('click', '.experiment-card-selector', function() {
      let card = $(this).closest('.experiment-card');
      let experimentId = card.data('id');
      // Determine whether ID is in the list of selected project IDs
      let index = $.inArray(experimentId, selectedExperiments);

      // If checkbox is checked and row ID is not in list of selected project IDs
      if (this.checked && index === -1) {
        $(this).closest('.experiment-card').addClass('selected');
        selectedExperiments.push(experimentId);
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        $(this).closest('.experiment-card').removeClass('selected');
        selectedExperiments.splice(index, 1);
      }
      updateExperimentsToolbar();
    });
  }

  function initSelectAllCheckbox() {
    $(experimentsPage).on('click', '.sci-checkbox.select-all', function() {
      var selectAll = this.checked;
      $.each($('.experiment-card-selector'), function() {
        if (this.checked !== selectAll) this.click();
      });
    });
  }

  function initArchiveRestoreToolbarButtons() {
    $(experimentsPage)
      .on('ajax:before', '.archive-experiments-form, .restore-experiments-form', function() {
        let buttonForm = $(this);
        buttonForm.find('input[name="experiments_ids[]"]').remove();
        selectedExperiments.forEach(function(id) {
          $('<input>').attr({
            type: 'hidden',
            name: 'experiments_ids[]',
            value: id
          }).appendTo(buttonForm);
        });
      })
      .on('ajax:success', '.archive-experiments-form, .restore-experiments-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.message, 'success');
        // Project saved, reload view
        refreshCurrentView();
      })
      .on('ajax:error', '.archive-experiments-form, .restore-experiments-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });
  }

  function appendActionModal(modal) {
    $('#content-wrapper').append(modal);
    modal.modal('show');
    modal.find('.selectpicker').selectpicker();
    // Remove modal when it gets closed
    modal.on('hidden.bs.modal', function() {
      $(this).remove();
    });
    validateMoveModal(modal)
  }

  function validateMoveModal(modal) {
    if (modal[0].id.match(/move-experiment-modal-[0-9]*/)) {
      let form = $(modal).find('form');
      form.on('ajax:success', function(e, data) {
        animateSpinner(form, true);
        window.location.replace(data.path);
      }).on('ajax:error', function(e, error) {
        animateSpinner(form, false);
        form.clearFormErrors();
        let msg = JSON.parse(error.responseText);
        renderFormError(e, form.find('#experiment_project_id'), msg.message.toString());
      });
    }
  }


  function initEditMoveDuplicateToolbarButton() {
    let forms = '.edit-experiments-form, .move-experiments-form, .clone-experiments-form';
    $(experimentsPage)
      .on('ajax:before', forms, function() {
        let buttonForm = $(this);
        buttonForm.find('input[name="id"]').remove();
        $('<input>').attr({
          type: 'hidden',
          name: 'id',
          value: selectedExperiments[0]
        }).appendTo(buttonForm);
      })
      .on('ajax:success', forms, function(ev, data) {
        appendActionModal($(data.html));
      })
      .on('ajax:error', forms, function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });
  }

  function initNewExperimentToolbarButton() {
    let forms = '.new-experiment-form';
    $(experimentsPage)
      .on('ajax:success', forms, function(ev, data) {
        appendActionModal($(data.html));
      })
      .on('ajax:error', forms, function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });
  }

  function loadExperimentWorkflowImages() {
    $('.experiment-card').each(function() {
      let card = $(this);
      let container = $(this).find('.workflowimg-container').first();
      if (container.data('workflowimg-present') === false) {
        let imgUrl = container.data('workflowimg-url');
        card.find('.workflowimg-spinner').removeClass('hidden');
        $.ajax({
          url: imgUrl,
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            card.find('.workflowimg-container').html(data.workflowimg);
          },
          error: function() {
            card.find('.workflowimg-spinner').addClass('hidden');
          }
        });
      }
    });
  }

  function init() {
    $('#content-wrapper').on('ajax:success', '.experiment-action-link', function(ev, data) {
      appendActionModal($(data.html));
    });

    $('#content-wrapper')
      .on('ajax:beforeSend', '.experiment-action-form', function() {
        animateSpinner();
      })
      .on('ajax:success', '.experiment-action-form', function() {
        $(this).closest('.modal').modal('hide');
        refreshCurrentView();
        animateSpinner(null, false);
      })
      .on('ajax:error', '.experiment-action-form', function(ev, data) {
        animateSpinner(null, false);
        $(this).renderFormErrors('experiment', data.responseJSON);
      });

    initExperimentsFilters();
    initSorting();
    loadCardsView();
    initProjectsViewModeSwitch();
    initExperimentsSelector();
    initArchiveRestoreToolbarButtons();
    initEditMoveDuplicateToolbarButton();
    initNewExperimentToolbarButton();
    initSelectAllCheckbox();
  }

  init();
}());
