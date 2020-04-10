/* global dropdownSelector I18n */

var DataTableHelpers = (function() {
  return {
    initLengthApearance: function(dataTableWraper) {
      var tableLengthSelect = $(dataTableWraper).find('.dataTables_length select');
      if (tableLengthSelect.val() == null) {
        tableLengthSelect.val(10).change();
      }
      $.each(tableLengthSelect.find('option'), (i, option) => {
        option.innerHTML = I18n.t('repositories.index.show_per_page', { number: option.value });
      });
      $(dataTableWraper).find('.dataTables_length')
        .append(tableLengthSelect).find('label')
        .remove();
      dropdownSelector.init(tableLengthSelect, {
        noEmptyOption: true,
        singleSelect: true,
        closeOnSelect: true,
        selectAppearance: 'simple'
      });
    },

    initSearchField: function(dataTableWraper) {
      var tableFilterInput = $(dataTableWraper).find('.dataTables_filter input');
      tableFilterInput.attr('placeholder', I18n.t('repositories.index.filter_inventory'))
        .addClass('sci-input-field')
        .css('margin', 0);
      $('.dataTables_filter').append(`
          <div class="sci-input-container left-icon">
            <i class="fas fa-search"></i>
          </div>`).find('.sci-input-container').prepend(tableFilterInput);
      $('.dataTables_filter').find('label').remove();
    }
  };
}());
