/* global dropdownSelector I18n */

var DataTableHelpers = (function() {
  return {
    initLengthAppearance: function(dataTableWraper) {
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
        disableSearch: true,
        selectAppearance: 'simple'
      });
    },

    initSearchField: function(dataTableWraper, searchText) {
      var tableFilterInput = $(dataTableWraper).find('.dataTables_filter input');
      tableFilterInput.attr('placeholder', searchText)
        .addClass('sci-input-field search-field')
        .css('margin', 0);
      $('.dataTables_filter').append(`
          <button class="btn btn-light icon-btn search-icon"
                  title="${I18n.t('repositories.show.button_tooltip.search')}">
            <i class="fas fa-search"></i>
          </button>
          <div class="sci-input-container right-icon search-container">
            <i class="fas fa-search"></i>
          </div>`).find('.sci-input-container').prepend(tableFilterInput);
      $('.dataTables_filter').find('label').remove();

      $('.dataTables_filter').on('click', '.search-icon', function() {
        $('.dataTables_filter').find('.search-container').addClass('expand');
        $(this).addClass('collapsed');
        $('.dataTables_filter .search-field').focus();
      });

      $('.dataTables_filter').on('focusout', '.search-field', function() {
        if (this.value.length === 0) {
          $('.dataTables_filter').find('.search-container').removeClass('expand');
          $('.dataTables_filter .search-icon').removeClass('collapsed');
        }
      });
    }
  };
}());

function DataTableCheckboxes(tableWrapper, config) {

  /* config = {
    checkboxSelector: selector for checkboxes,
    selectAllSelector: selector for select all checkbox
    onChanged: callback when the state of the checkbox is changed
  }*/

  this.selectedRows = [];
  this.tableWrapper = $(tableWrapper);
  this.config = config;

  this.initCheckboxes();
  this.initSelectAllCheckbox();
}

DataTableCheckboxes.prototype.checkRowStatus = function(row) {
  var checkbox = $(row).find(this.config.checkboxSelector);
  if (this.selectedRows.includes(row.id)) {
    $(row).addClass('selected');
    checkbox.attr('checked', true);
  } else {
    $(row).removeClass('selected');
    checkbox.attr('checked', false);
  }
};

DataTableCheckboxes.prototype.checkSelectAllStatus = function() {
  var checkboxes = this.tableWrapper.find(this.config.checkboxSelector + ':not(:disabled)');
  var selectedCheckboxes = this.tableWrapper.find(this.config.checkboxSelector + ':checked');
  var selectAllCheckbox = this.tableWrapper.find(this.config.selectAllSelector);
  selectAllCheckbox.prop('indeterminate', false);
  if (selectedCheckboxes.length === 0) {
    selectAllCheckbox.prop('checked', false);
  } else if (selectedCheckboxes.length === checkboxes.length) {
    selectAllCheckbox.prop('checked', true);
  } else {
    selectAllCheckbox.prop('indeterminate', true);
  }
};

DataTableCheckboxes.prototype.clearSelection = function() {
  var rows = this.tableWrapper.find('tbody tr');
  this.selectedRows = [];
  $.each(rows, (i, row) => {
    $(row).removeClass('selected');
    $(row).find(this.config.checkboxSelector).attr('checked', false);
  });
  this.checkSelectAllStatus();
};

// private methods

DataTableCheckboxes.prototype.initCheckboxes = function() {
  this.tableWrapper.on('click', '.table tbody tr', (e) => {
    var checkbox = $(e.currentTarget).find(this.config.checkboxSelector);
    if (checkbox.attr('disabled') || $(e.target).is('a')) return;
    checkbox.prop('checked', !checkbox.prop('checked'));
    this.selectRow(e.currentTarget);
  }).on('click', this.config.checkboxSelector, (e) => {
    this.selectRow($(e.currentTarget).closest('tr')[0]);
    e.stopPropagation();
  });
};

DataTableCheckboxes.prototype.selectRow = function(row) {
  var id = row.id;
  if (this.selectedRows.includes(id)) {
    this.selectedRows.splice(this.selectedRows.indexOf(id), 1);
  } else {
    this.selectedRows.push(id);
  }
  $(row).toggleClass('selected');
  this.checkSelectAllStatus();

  if (this.config.onChanged) this.config.onChanged();
};

DataTableCheckboxes.prototype.initSelectAllCheckbox = function() {
  this.tableWrapper.on('click', this.config.selectAllSelector, (e) => {
    var selectAllCheckbox = $(e.currentTarget);
    var rows = this.tableWrapper.find('tbody tr');
    $.each(rows, (i, row) => {
      var checkbox = $(row).find(this.config.checkboxSelector);
      if (checkbox.prop('checked') === selectAllCheckbox.prop('checked') || checkbox.attr('disabled')) return;

      checkbox.prop('checked', selectAllCheckbox.prop('checked'));
      this.selectRow(row);
    });
  });
};
