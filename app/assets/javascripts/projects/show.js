/* global filterDropdown */
(function() {
  var cardsWrapper = '#cardsWrapper'

  var selectedExperiments = [];

  let experimentsCurrentSort;
  let experimentsViewSearch;
  let startedOnFromFilter;
  let startedOnToFilter;
  let modifiedOnFromFilter;
  let modifiedOnToFilter;
  let archivedOnFromFilter;
  let archivedOnToFilter;

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
      startedOnFromFilter = $startedOnFromFilter.val();
      startedOnToFilter = $startedOnToFilter.val();
      modifiedOnFromFilter = $modifiedOnFromFilter.val();
      modifiedOnToFilter = $modifiedOnToFilter.val();
      archivedOnFromFilter = $archivedOnFromFilter.val();
      archivedOnToFilter = $archivedOnToFilter.val();
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

  function updateExperimentsToolbar() {

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

  function refreshCurrentView() {
    loadCardsView();
    Sidebar.reload({
      sort: experimentsCurrentSort,
      view_mode: 'active'
    });
  }

  function loadCardsView() {
    var viewContainer = $(cardsWrapper);
    $.ajax({
      url: viewContainer.data('experiments-cards-url'),
      type: 'GET',
      dataType: 'json',
      data: {
        view_mode: 'active',
        sort: experimentsCurrentSort,
        search: experimentsViewSearch,
        created_on_from: startedOnFromFilter,
        created_on_to: startedOnToFilter,
        updated_on_from: modifiedOnFromFilter,
        updated_on_to: modifiedOnToFilter,
        archived_on_from: archivedOnFromFilter,
        archived_on_to: archivedOnToFilter
      },
      success: function(data) {
        viewContainer.find('.card').remove();
        viewContainer.append(data.cards_html);
        selectedExperiments.length = 0;
        updateExperimentsToolbar();
      },
      error: function() {
        viewContainer.html('Error loading project list');
      }
    });
  }

  function init() {
    $('.workflowimg-container').each(function() {
      let container = $(this);
      if (container.data('workflowimg-present') === false) {
        let imgUrl = container.data('workflowimg-url');
        container.find('.workflowimg-spinner').removeClass('hidden');
        $.ajax({
          url: imgUrl,
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            container.html(data.workflowimg);
          },
          error: function() {
            container.find('.workflowimg-spinner').addClass('hidden');
          }
        });
      }
    });

    initExperimentsFilters();
    initSorting()
    loadCardsView();
  }

  init();
}());
