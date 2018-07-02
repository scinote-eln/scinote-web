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
    var formData     = this.formData;

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
        var type        = $(colHeader).attr('data-type');
        var colHeaderId = $(colHeader).attr('id');
        var cell        = cells[colHeaderId] || '';
        td.html(changeToFormField('repository_cell',
                                  colHeaderId,
                                  type,
                                  cell,
                                  list_columns));
        appendNewElementToFormData(cell, colHeaderId, formData);
      }
    });
    initializeDataBinding(this.repositoryItemElement, formData);
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
        formBindingsData[tableCellId] = new File(cell.asset_preview);
      } else {
        formBindingsData[tableCellId] = cell.value;
      }
    });
    return formBindingsData;
  }

  /**
   * Handles select picker default value
   * 
   * @returns {undefinded}
   */
  RepositoryItemEditForm.prototype.initializeSelectpickerValues = function(selectpicker) {
    $('.bootstrap-select').each(function(_, dropdown) {
      var selectedValue = $($(dropdown).find('select')[0]).data('selected-value');
      var value         = '-1'
      $(dropdown).find('option').each(function(_, option) {
        $(option).removeAttr('selected');  
        if($(option).val() === selectedValue.toString()) {
          $(option).attr('selected', true);
          value = $(option).attr('value');
        }
      });
      $(dropdown).parent().attr("list_item_id", value);
      $(dropdown).val(value);
    });
    selectpicker();
  }

  /** 
   *  |-----------------|
   *  | Private methods |
   *  |-----------------|
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
   *  Takes object and creates an input file field, contains a hidden
   *  input field which is triggered on button click and we get the uploaded
   *  file from there.
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
        "<input type='file' name='" + name + "' data-id='" + id + "' style='display:none'>" +
        "<button class='form-control' data-object='" +
        object + "' name='" + name + "' value='" + value + "' id='" + id + "'>Choose File</button></div>" +
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
    var val  = undefined; 
    var html = '<select id="' + id + '" class="form-control selectpicker repository-dropdown" ';
    html     += 'data-selected-value="" data-abs-min-length="2" data-live-search="true" ';
    html     += 'data-container="body" column_id="' + column_id +'">';
    html     += '<option value="-1"></option>';
    $.each(options, function(index, value) {
      var selected = '';
      if (current_value === value[1]) {
        selected = 'selected';
        val      = value[0];     
      }
      html += '<option value="' + value[0] + '" ' + selected + '>';
      html += value[1] + '</option>';
    });
    html += '</select>';
    return (val) ? $(html).attr('data-selected-value', val)[0] : html;
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
    var cell_id = generateInputFieldReference(cell, name);
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
   * 
   * @param {String} type
   * @param {Object} input
   * @param {Object} formData
   * 
   * @returns {undefined}
   */
  function _addSelectedFile(type, input, formData) {
    if (type === 'RepositoryAssetValue') {
      $(input.find('input[type="file"]')[0]).on('change', function(){
        this.dataset.changed = 'true';
      });
      $(input.find('button')[0]).on('click', function(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        var input = $(this).parent().find('input[type="file"]')
        input.trigger('click');
        initFileHandler(input, formData);
      });
    }
  }

  /**
   * Handle extraction of file from the input field
   * 
   * @param {Object} formData
   * 
   * @returns {undefined}
   */
  function initFileHandler($inputField, formData) {
    $inputField.on('change', function() {
      var inputElement = $inputField[0];
      if (inputElement.files[0]) {
        formData[inputField.data('id')] = inputElement.files[0];
      }
    })  
  }

  /**
   * Initializes the data binding for form object
   * 
   * @param {Object} row_node
   * @param {Object} data
   * 
   * @returns {undefined}
   */
  function initializeDataBinding(row_node, data) {
    var uiBindings = {};
    $.each(_.keys(data), function(i, element) {
      uiBindings['#' + element] = element;  
    })
    $(row_node).my({ui: uiBindings}, data);
  }

  /**
   * Generates the input tag id that will be used in the formData object
   * 
   * @param {Object} cell 
   * @param {String} column_id 
   * 
   * @returns {String}
   */
  function generateInputFieldReference(cell, column_id) {
    if (cell.repository_cell_id) {
      return 'cellId-' + cell.repository_cell_id;
    } 
    return 'new-element-col-id-' + column_id;  
  }

  /**
   * Appends aditional fields to form data object
   * @param {Object} cell 
   * @param {String} column_id 
   * @param {Object} formData 
   * 
   * @returns {undefined}
   */
  function appendNewElementToFormData(cell, column_id, formData) {
    if (!cell.repository_cell_id) {
      formData[generateInputFieldReference(cell, column_id)] = undefined;
    }
  }
})(window);