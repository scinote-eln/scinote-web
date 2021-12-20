(function() {
  'use strict';

  function initFilterListListeners() {
    $(document).on('input', 'input[data-action="filter-list"]', function() {
      let list = document.getElementById($(this).attr('data-target'));
      let searchTerm = $(this).val();
      $(list).find('div[data-filter-item]').each((_, el) => {
        let itemValue = el.getAttribute('data-filter-item').toLowerCase();
        if (itemValue.search(searchTerm.toLowerCase()) === -1) {
          el.classList.add('hidden');
        } else {
          el.classList.remove('hidden');
        }
      });
    });
  }

  $(document).one('turbolinks:load', initFilterListListeners);
}());
