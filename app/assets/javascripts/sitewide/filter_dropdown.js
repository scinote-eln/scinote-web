var filterDropdown = (function() {
  var $filterContainer = '';
  let filtersEnabled = null;
  let textFilterVal = null;

  function initClearButton() {
    $('.clear-button', $filterContainer).click(function(e) {
      e.stopPropagation();
      e.preventDefault();
      $filterContainer.trigger('filter:clear');
      $filterContainer.removeClass('filters-applied');
      textFilterVal = null;
    });
  }

  function preventDropdownClose() {
    $filterContainer.on('click', '.dropdown-menu', function(e) {
      if (!$(e.target).is('input,a')) {
        e.stopPropagation();
        e.preventDefault();
        $('#textSearchFilterHistory').hide();
        $('#textSearchFilterInput', $filterContainer).closest('.dropdown').removeClass('open');
        $filterContainer.trigger('filter:clickBody');
      }
    });
  }

  function initSearchField(filtersEnabledFunction) {
    var $textFilter = $('#textSearchFilterInput', $filterContainer);

    $filterContainer.on('show.bs.dropdown', function() {
      if (!$(this).hasClass('filters-applied')) {
        $(this).find('input').each(function() {
          // .data-field inputs are dropdownSelector data fields
          $(this).val($(this).hasClass('data-field') ? '[]' : '')
        });
      }

      let $filterDropdown = $filterContainer.find('.dropdown-menu');
      let teamId = $filterDropdown.data('team-id');
      $('#textSearchFilterHistory').find('li').remove();
      try {
        let storagePath = `${$filterDropdown.data('search-field-history-key')}/${teamId}/recent_search_keywords`;
        let recentSearchKeywords = JSON.parse(localStorage.getItem(storagePath));
        $.each(recentSearchKeywords, function(i, keyword) {
          const listItem = $(`<li class="dropdown-item">
              <a class="projects-search-keyword" href="#" data-keyword="${keyword}">
                <i class="fas fa-history"></i>
                <span class="keyword-text">${keyword}</span>
              </a>
            </li>`);

          listItem.find('.projects-search-keyword').click(function(e) {
            e.preventDefault();
            const clickedKeyword = $(this).data('keyword');
            if (clickedKeyword?.trim().length > 0) {
              textFilterVal = clickedKeyword;
            }
            else {
              textFilterVal = null;
            }
          });
          $('#textSearchFilterHistory').append(listItem);
        });
      } catch (error) {
        console.error(error);
      }
      if (textFilterVal) {
        $('#textSearchFilterInput').val(textFilterVal);
      }
    }).on('hide.bs.dropdown', function(e) {
      if (e.target === e.currentTarget) {
        $('#textSearchFilterHistory').hide();
        if (filtersEnabledFunction() || filtersEnabled) {
          $('.apply-filters', $filterContainer).click();
        }
      }
    });

    $textFilter.click(function(e) {
      e.stopPropagation();
      $('#textSearchFilterHistory').toggle();
      $(e.currentTarget).closest('.dropdown').toggleClass('open');
    }).on('input', (e) => {
      $('#textSearchFilterHistory').hide();
      $(e.currentTarget).closest('.dropdown').removeClass('open');
    });

    $filterContainer.on('click', '.projects-search-keyword', function(e) {
      e.stopPropagation();
      e.preventDefault();
      $textFilter.val($(this).data('keyword'));
      $('#textSearchFilterHistory').hide();
      $textFilter.closest('.dropdown').removeClass('open');
    });
  }

  function initApplyButton() {
    $('.apply-filters', $filterContainer).click(function(e) {
      e.stopPropagation();
      e.preventDefault();

      let $filterDropdown = $filterContainer.find('.dropdown-menu');
      let teamId = $filterDropdown.data('team-id');
      let projectsViewSearch = $('#textSearchFilterInput').val();
      try {
        let storagePath = `${$filterDropdown.data('search-field-history-key')}/${teamId}/recent_search_keywords`;
        let recentSearchKeywords = JSON.parse(localStorage.getItem(storagePath));
        if (!Array.isArray(recentSearchKeywords)) recentSearchKeywords = [];
        if (recentSearchKeywords.indexOf(projectsViewSearch) !== -1) {
          recentSearchKeywords.splice(recentSearchKeywords.indexOf(projectsViewSearch), 1);
        }
        if (recentSearchKeywords.length > 4) {
          recentSearchKeywords = recentSearchKeywords.slice(0, 4);
        }
        recentSearchKeywords.unshift(projectsViewSearch);
        localStorage.setItem(storagePath, JSON.stringify(recentSearchKeywords));

      } catch (error) {
        console.error(error);
      }

      $filterContainer.trigger('filter:apply');
      $(this).closest('.dropdown').removeClass('open');
    });
  }

  function initCloseButton() {
    $('.close', $filterContainer).click(function() {
      $(this).closest('.dropdown').removeClass('open');
    });
  }

  function initDateTimePickerComponent() {
    const dateTimePickers = document.querySelectorAll('.vue-date-time-picker-filter');
    dateTimePickers.forEach((dateTimePicker) => {
      $((`#${dateTimePicker.id}`)).removeClass('vue-date-time-picker-filter');
      window.initDateTimePickerComponent(`#${dateTimePicker.id}`);
    });
  }

  return {
    init: function(filtersEnabledFunction) {
      $filterContainer = $('.filter-container');
      initClearButton();
      preventDropdownClose();
      initApplyButton();
      initCloseButton();
      initDateTimePickerComponent();
      initSearchField(filtersEnabledFunction);
      return $filterContainer;
    },
    toggleFilterMark: function(filterContainer, filtersEnabledArg) {
      if (filtersEnabledArg) {
        filterContainer.addClass('filters-applied');
        filtersEnabled = filtersEnabledArg;
      } else {
        filterContainer.removeClass('filters-applied');
        filtersEnabled = null;
      }
    }
  };
}());
