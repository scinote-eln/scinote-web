/* global animateSpinner filterDropdown Turbolinks HelperModule InfiniteScroll AsyncDropdown
  GLOBAL_CONSTANTS loadPlaceHolder */
/* eslint-disable no-use-before-define */
(function() {
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

  function updateExperimentsToolbar() {
    if (window.actionToolbarComponent) {
      window.actionToolbarComponent.fetchActions({ experiment_ids: selectedExperiments });
      window.actionToolbarComponent.setReloadCallback(refreshCurrentView);
    }
  }

  function initProjectsViewModeSwitch() {
    $('.button-to.selected').removeClass('btn-light');
    $('.button-to.selected').addClass('form-dropdown-state-item');
    $('.button-to.selected .view-switch-list-span').css('color', 'white');
    $('.button-to.selected').removeClass('selected');

    $(experimentsPage)
      .on('ajax:success', '.change-experiments-view-type-form', function(ev, data) {
        $('.view-switch-btn-name').text($(ev.target).find('.button-to').text());

        $(cardsWrapper).removeClass('list cards').addClass(data.cards_view_type_class);

        $(experimentsPage).find('.cards-switch .button-to').removeClass('form-dropdown-state-item');
        $(experimentsPage).find('.cards-switch .button-to').addClass('btn-light');
        $(experimentsPage).find('.cards-switch .button-to .view-switch-list-span').css('color', 'black');

        $(ev.target).find('.button-to').removeClass('btn-light');
        $(ev.target).find('.button-to').addClass('form-dropdown-state-item');
        $(ev.target).find('.button-to .view-switch-list-span').css('color', 'white');

        $(ev.target).parents('.dropdown.view-switch').removeClass('open');
      })
      .on('ajax:error', '.change-projects-view-type-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
      });

    $(experimentsPage).on('click', '.archive-switch', function() {
      Turbolinks.visit($(this).data('url'));
    });
  }

  function initCardData(viewContainer, data) {
    viewContainer.find('.card, .no-results-container, .no-data-container').remove();
    viewContainer.removeClass('no-results no-data');

    if (viewContainer.find('.list').length) {
      viewContainer.find('.table-header').show();
    }

    viewContainer.append(data.cards_html);
    if (viewContainer.find('.no-results-container').length) {
      viewContainer.addClass('no-results');
    }

    if (viewContainer.find('.no-data-container').length) {
      viewContainer.addClass('no-data');
      viewContainer.find('.table-header').hide();
    }
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

    loadPlaceHolder($(cardsWrapper), $('#experimentPlaceholder'), '.experiment-placeholder');
    $.ajax({
      url: cardsUrl,
      type: 'GET',
      dataType: 'json',
      data: requestParams,
      success: function(data) {
        initCardData(viewContainer, data);
        updateExperimentsToolbar();
        loadExperimentWorkflowImages();

        selectedExperiments.length = 0;

        InfiniteScroll.init(cardsWrapper, {
          url: cardsUrl,
          eventTarget: window,
          placeholderTemplate: '#experimentPlaceholder',
          endOfListTemplate: '#experimentEndOfList',
          pageSize: pageSize,
          lastPage: !data.next_page,
          customResponse: (response) => {
            $(response.cards_html).appendTo(cardsWrapper);
          },
          customParams: (params) => {
            return { ...params, ...requestParams };
          }
        });
      },
      error: function(e) {
        viewContainer.html('Error loading experiment list');
      },
      complete: function() {
        updateSelectAllCheckbox();
      }
    });
  }

  function refreshCurrentView() {
    loadCardsView();
    window.navigatorContainer.reloadChildrenLevel = true;
  }

  function selectDate($field) {
    let datePicker = $field.data('dateTimePicker');
    if (datePicker && datePicker.date) {
      return datePicker.date.toString();
    }
    return null;
  }

  function initExperimentsFilters() {
    var $filterDropdown = filterDropdown.init(filtersEnabled);

    let $experimentsFilter = $('.experiments-filters');
    let $startedOnFromFilter = $('.started-on-filter .from-date', $experimentsFilter);
    let $startedOnToFilter = $('.started-on-filter .to-date', $experimentsFilter);
    let $modifiedOnFromFilter = $('.modified-on-filter .from-date', $experimentsFilter);
    let $modifiedOnToFilter = $('.modified-on-filter .to-date', $experimentsFilter);
    let $archivedOnFromFilter = $('.archived-on-filter .from-date', $experimentsFilter);
    let $archivedOnToFilter = $('.archived-on-filter .to-date', $experimentsFilter);
    let $textFilter = $('#textSearchFilterInput', $experimentsFilter);

    function getFilterValues() {
      startedOnFromFilter = selectDate($startedOnFromFilter);
      startedOnToFilter = selectDate($startedOnToFilter);
      modifiedOnFromFilter = selectDate($modifiedOnFromFilter);
      modifiedOnToFilter = selectDate($modifiedOnToFilter);
      archivedOnFromFilter = selectDate($archivedOnFromFilter);
      archivedOnToFilter = selectDate($archivedOnToFilter);
      experimentsViewSearch = $textFilter.val();
    }

    function filtersEnabled() {
      getFilterValues();

      return experimentsViewSearch
             || startedOnFromFilter
             || startedOnToFilter
             || modifiedOnFromFilter
             || modifiedOnToFilter
             || archivedOnFromFilter
             || archivedOnToFilter;
    }


    function appliedFiltersMark() {
      filterDropdown.toggleFilterMark($filterDropdown, filtersEnabled());
    }

    $filterDropdown.on('filter:apply', function() {
      appliedFiltersMark();
      refreshCurrentView();
    });

    // Clear filters
    $filterDropdown.on('filter:clear', function() {
      $(this).find('input').val('');
      $startedOnFromFilter.data('dateTimePicker').clearDate();
      $startedOnToFilter.data('dateTimePicker').clearDate();
      $modifiedOnFromFilter.data('dateTimePicker').clearDate();
      $modifiedOnToFilter.data('dateTimePicker').clearDate();
      $archivedOnFromFilter.data('dateTimePicker').clearDate();
      $archivedOnToFilter.data('dateTimePicker').clearDate();
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

  function updateSelectAllCheckbox() {
    const tableWrapper = $(cardsWrapper);
    const checkboxesCount = $('.sci-checkbox.experiment-card-selector', tableWrapper).length;
    const selectedCheckboxesCount = selectedExperiments.length;
    const selectAllCheckbox = $('.sci-checkbox.select-all', tableWrapper);

    selectAllCheckbox.prop('indeterminate', false);
    if (selectedCheckboxesCount === 0) {
      selectAllCheckbox.prop('checked', false);
    } else if (selectedCheckboxesCount === checkboxesCount) {
      selectAllCheckbox.prop('checked', true);
    } else {
      selectAllCheckbox.prop('indeterminate', true);
    }
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

      updateSelectAllCheckbox();
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

  function appendActionModal(modal) {
    $('#projectShowWrapper').append(modal);
    modal.modal('show');
    modal.find('.selectpicker').selectpicker();
    // Remove modal when it gets closed
    modal.on('hidden.bs.modal', function() {
      $(this).remove();
    });
    validateMoveModal(modal);
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

  $(document).on('shown.bs.modal', function() {
    var inputField = $('#experiment-name');
    var value = inputField.val();
    inputField.focus().val('').val(value);
  });

  function initNewExperimentToolbarButton() {
    let forms = '.new-experiment-form';
    $(experimentsPage)
      .on('submit', forms, function() {
        $(this).find("button[type='submit']").prop('disabled', true);
      })
      .on('ajax:success', forms, function(ev, data) {
        appendActionModal($(data.html));
        $(this).find("button[type='submit']").prop('disabled', false);
      })
      .on('ajax:error', forms, function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
        $(this).find("button[type='submit']").prop('disabled', false);
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
    $('#projectShowWrapper').on('ajax:success', '.experiment-action-link', function(ev, data) {
      appendActionModal($(data.html));
    });

    $(document)
      .on('ajax:success', '.experiment-action-form', function(_event, data) {
        $(this).closest('.modal').modal('hide');
        if (data.path) {
          window.location.replace(data.path);
        }
      })
      .on('ajax:error', '.experiment-action-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });

    window.initActionToolbar();

    initExperimentsFilters();
    initSorting();
    loadCardsView();
    initProjectsViewModeSwitch();
    initExperimentsSelector();
    initNewExperimentToolbarButton();
    initSelectAllCheckbox();
    AsyncDropdown.init($('#projectShowWrapper'));
  }

  init();
}());
