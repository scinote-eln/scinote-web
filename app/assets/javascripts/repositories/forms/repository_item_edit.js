//= require sugar.min
//= require jquerymy-1.2.14.min

(function(global) {
  'use strict';
  
  /**
   * RepositoryItemEditForm generates the html inputs for
   * repository item and returns the form data object
   * 
   * @param {Object} itemData - repository item data fetched from the API 
   * @param {Object} repositoryItemElement - row node in the table
   */
  global.RepositoryItemEditForm = function(itemData, repositoryItemElement) {
    this.itemData              = itemData;
    this.repositoryItemElement = repositoryItemElement
    this.formData              = this.composeFormData(itemData)
  }

  /**
   * Generates the input fields
   * 
   * @param {Object} table - datatable.js object
   * @returns {undefinded}
   */
  RepositoryItemEditForm.prototype.renderForm = function(table) {
    var colIndex     = getColumnIndex(table, '#row-name');
    var cells        = this.itemData.repository_row.repository_cells;
    var list_columns = this.itemData.repository_row.repository_column_items;

    if (colIndex) {
      $(this.repositoryItemElement).children('td').eq(colIndex)
             .html(changeToInputField('repository_row',
                                      'name',
                                      this.itemData.repository_row.name,
                                      'rowName'));
    }

    $(this.repositoryItemElement).children('td').each(function(i) {
        var td        = $(this);
        var rawIndex  = table.column.index('fromVisible', i);
        var colHeader = table.column(rawIndex).header();

        if ($(colHeader).hasClass('repository-column')) {
          var type = $(colHeader).attr('data-type');
          // Check if cell on this record exists
          var cell = cells[$(colHeader).attr('id')] || '';
          td.html(changeToFormField('repository_cell',
                                     $(colHeader).attr('id'),
                                     type,
                                     cell,
                                     list_columns));
          _addSelectedFile(type, $(this).find('input')[0]);
        }
    });
    initializeDataBinding(this.repositoryItemElement, this.formData);
  }

  /**
   * Parse received data in to a from object
   * 
   * @param {Object} itemData - json representations of repository item
   * 
   * @returns {Object}
   */
  RepositoryItemEditForm.prototype.composeFormData = function(itemData) {
    var formBindingsData = {};
    formBindingsData['rowName'] = itemData.repository_row.name;
    $.each(itemData.repository_row.repository_cells, function(i, cell) {
      var tableCellId = 'cellId-' + cell.repository_cell_id;
      if(cell.type === 'RepositoryAssetValue') {
        formBindingsData[tableCellId] = new Blob([cell.value], { type: cell.value.file_content_type });
      } else {
        formBindingsData[tableCellId] = cell.value;
      }
    });
    return formBindingsData;
  }

  RepositoryItemEditForm.prototype.getRowNewData = function() {
    return this.formData;
  }
  /**
   * Private methods
   */

  /**
   * Takes object and surrounds it with input
   * 
   *  @param {Object} object
   *  @param {String} name
   *  @param {String} value
   *  @param {String} id
   * 
   *  @returns (String)
   */
  function changeToInputField(object, name, value, id) {
    return "<div class='form-group'><input class='form-control' data-object='" +
        object + "' name='" + name + "' value='" + value + "' id='" + id +  "'></input></div>";
  }

  /**
   *  Takes object and creates an input file field
   * 
   *  @param {Object} object
   *  @param {String} name
   *  @param {String} value
   *  @param {String} id
   * 
   *  @returns (String)
   */
  function changeToInputFileField(object, name, value, id) {
    return "<div class='repository-input-file-field'><div class='form-group'>" +
        "<input type='file' class='form-control' data-object='" +
        object + "' name='" + name + "' value='" + value + "' id='" + id + "'></div>" +
        "<a onClick='clearFileInput(this)'>" +
        "<i class='fas fa-times'></i>" +
        "</a></div>";
  }

  /**
   * Returns the colum index
   * 
   * @param {Object} table 
   * @param {String} id 
   * 
   * @returns (Boolean | Number)
   */
  function getColumnIndex(table, id) {
    if(id < 0)
      return false;  
    return table.column(id).index('visible');
  }

  /**
   * Genrates list items dropdown element
   * 
   * @param {Array} options 
   * @param {String} current_value 
   * @param {Number} column_id
   * @param {String} id
   * 
   * @returns (String)
   */
  function _listItemDropdown(options, current_value, column_id, id) {
    var html = '<select id="' + id + '" class="form-control selectpicker repository-dropdown" ';
    html    += 'data-abs-min-length="2" data-live-search="true" ';
    html    += 'data-container="body" column_id="' + column_id +'">';
    html    += '<option value="-1"></option>';
    $.each(options, function(index, value) {
      var selected = (current_value === value[1]) ? 'selected' : '';
      html         += '<option value="' + value[0] + '" ' + selected + '>';
      html         += value[1] + '</option>';
    });
    html += '</select>';
    return html;
  }
  /**
   * Takes an object and creates custom html element
   * 
   * @param {String} object
   * @param {String} name
   * @param {String} column_type
   * @param {Object} cell
   * @param {Object} list_columns
   * 
   * @returns (String)
   */
  function changeToFormField(object, name, column_type, cell, list_columns) {
    var cell_id = 'cellId-' + cell.repository_cell_id;  
    var value   = cell.value || '';
    if (column_type === 'RepositoryListValue') {
      var column     = _.findWhere(list_columns, { column_id: parseInt(name) });
      var list_items = column.list_items || cell.list_items;
      return _listItemDropdown(list_items, value, parseInt(name), cell_id);
    } else if (column_type === 'RepositoryAssetValue') {
      return changeToInputFileField('repository_cell_file', name, value, cell_id);
    } else {
      return changeToInputField(object, name, value, cell_id);
    }
  }

  /**
   * Append the change listener to file field
   * @param {String} type
   * @param {Object} input
   * 
   * @returns {undefined}
   */
  function _addSelectedFile(type, input) {
    if (type === 'RepositoryAssetValue') {
      $(input).on('change', function(){
        this.dataset.changed = 'true';
      });
    }
  }

  function initializeDataBinding(row_node, data) {
    var uiBindings = {};
    $.each(_.keys(data), function(i, element) {
      uiBindings['#' + element] = element;  
    })
    $(row_node).my({ui: uiBindings}, data);
    debugger;
  }
})(window);