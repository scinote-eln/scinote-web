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

  initDeleteFilterModal();
  initFilterInfoDropdown();
}());
