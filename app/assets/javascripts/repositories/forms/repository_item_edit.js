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
    this.repositoryItemElement = repositoryItemElement;
    this.formData              = this.composeFormData(itemData);
  }

  /**
   * Generates the input fields
   *
   * @param {Object} table - datatable.js object
   * @returns {undefinded}
   */
  RepositoryItemEditForm.prototype.renderForm = function(table) {
    var colIndex    = getColumnIndex(table, '#row-name');
    var cells       = this.itemData.repository_row.repository_cells;
    var listColumns = this.itemData.repository_row.repository_column_items;
    var formData    = this.formData;

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
                                  listColumns));
        addSelectedFile(type, colHeaderId);
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
      var tableCellId = 'colId-' + cell.cell_column_id;
      if(cell.type === 'RepositoryAssetValue') {
        formBindingsData[tableCellId] = new File([""], cell.value.file_file_name);
      } else {
        formBindingsData[tableCellId] = cell.value;
      }
    });
    return formBindingsData;
  }

  /**
   * Handles select picker default value
   *
   * @param {Object} node
   * @returns {undefinded}
   */
  RepositoryItemEditForm.prototype.initializeSelectpickerValues = function(node) {
    $($(node).find('.bootstrap-select')).each(function(_, dropdown) {
      var selectedValue = $($(dropdown).find('select')[0]).data('selected-value');
      var selectPicker  = $($(dropdown).find('select')[0]);
      var value         = '-1'
      $(dropdown).find('option').each(function(_, option) {
        $(option).removeAttr('selected');
        if($(option).val() === selectedValue.toString()) {
          $(option).attr('selected', true);
          value = $(option).attr('value');
        }
      });
      $(dropdown).parent().attr("list_item_id", value);
      selectPicker.val(value);
      selectPicker.selectpicker('refresh');
    });
  }

  /**
   * Creates a FormData object with the repository row data ready to be
   * sended on the server
   *
   * @param {Object} tableID
   * @param {Object} selectedRecord
   *
   * @returns (Object)
   */
  RepositoryItemEditForm.prototype.parseToFormObject = function(tableID, selectedRecord) {
    var formData = this.formData;
    var formDataObj = new FormData();
    var removeFileColumns = [];
    formDataObj.append('request_url', $(tableID).data('current-uri'));
    formDataObj.append('repository_row_id', $(selectedRecord).attr('id'));

    $(_.keys(this.formData)).each(function(_, element) {
      var value = formData[element];
      if (element === "rowName") {
        formDataObj.append('repository_row_name', value);
      } else {
        var colId = element.replace('colId-', '');
        var $el   = $('#' + element);
        // don't save anything if element is not visible
        if($el.length == 0) {
          return true;
        }
        if($el.attr('type') === 'file') {
          // handle deleting of element
          if($el.attr('remove') === "true") {
            removeFileColumns.push(colId);
            formDataObj.append('repository_cells[' + colId + ']', null);
          } else {
            formDataObj.append('repository_cells[' +  colId + ']',
                               getFileValue($el));
          }
        } else if(value.length >= 0) {
          formDataObj.append('repository_cells[' +  colId + ']', value);
        }
      }
    });
    formDataObj.append('remove_file_columns', JSON.stringify(removeFileColumns));
    return formDataObj;
  }
  /**
   *  |-----------------|
   *  | Private methods |
   *  |-----------------|
   */

   /**
    * Resolves the file cell on FormData creation
    *
    * @param {Object} elementId
    *
    * @returns (String | Object)
    */
  function getFileValue(element) {
    var file = element[0].files[0];
    return (file) ? file : '';
  }

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
    var fileName    = (value.file_file_name) ? value.file_file_name : I18n.t('general.file.no_file_chosen');
    var buttonLabel = I18n.t('general.file.choose');
    var html        = "<div class='repository-input-file-field'>" +
      "<div class='form-group'><div><input type='file' name='" + name + "' id='" +
      id + "' style='display:none' /><button class='btn btn-default' " +
      "data-object='" + object + "' name='" + name + "' value='" + value +
      "' data-id='" + id + "'>" + buttonLabel +
      "</button></div><div><p class='file-name-label'>" + truncateLongString(fileName, 20) +
      "</p></div>";
    if(value.file_file_name) {
      html += "<div><a data-action='removeAsset' ";
      html += "onClick='clearFileInput(this)'><i class='fas fa-times'></i></a>";
    } else {
      html += "<div><a data-action='removeAsset' onClick='clearFileInput(this)' ";
      html += "style='display:none'><i class='fas fa-times'></i></a>";
    }
    html += "</div></div></div>";

    return html;
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
   * @param {Number} columnId
   * @param {String} id
   *
   * @returns (String)
   */
  function _listItemDropdown(options, current_value, columnId, id) {
    var val  = undefined;
    var html = '<select id="' + id + '" class="form-control selectpicker repository-dropdown" ';
    html     += 'data-selected-value="" data-abs-min-length="2" data-live-search="true" ';
    html     += 'data-container="body" column_id="' + columnId +'">';
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
   * @param {Object} listColumns
   *
   * @returns (String)
   */
  function changeToFormField(object, name, column_type, cell, listColumns) {
    var cellId = generateInputFieldReference(name);
    var value   = cell.value || '';
    if (column_type === 'RepositoryListValue') {
      var column     = _.findWhere(listColumns,
                                  { column_id: parseInt(name, 10) });
      var list_items = column.list_items || cell.list_items;
      return _listItemDropdown(list_items, value, parseInt(name, 10), cellId);
    } else if (column_type === 'RepositoryAssetValue') {
      return changeToInputFileField('repository_cell_file', name, value, cellId);
    } else {
      return changeToInputField(object, name, value, cellId);
    }
  }

  /**
   * Append the change listener to file field
   *
   * @param {String} type
   * @param {String} name
   *
   * @returns {undefined}
   */
  function addSelectedFile(type, name) {
    var button  = $('button[data-id="' +
                    generateInputFieldReference(name) +
                    '"]');
    if (type === 'RepositoryAssetValue') {
      var fileInput = $(button.parent().find('input[type="file"]')[0]);
      button.on('click', function(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        fileInput.trigger('click');
        initFileHandler(fileInput);
      });
    }
  }

  /**
   * Handle extraction of file from the input field
   *
   * @param {Object} $inputField
   *
   * @returns {undefined}
   */
  function initFileHandler($inputField) {
    $inputField.on('change', function() {
      var input = $(this);
      var $label = $($(this).closest('.repository-input-file-field')
                            .find('.file-name-label')[0]);
      var file   = this.files[0];
      if (file) {
        $label.text(truncateLongString(file.name, 20));
        input.attr('remove', false);
        $($label.closest('.repository-input-file-field')
                .find('[data-action="removeAsset"]')[0]).show();
      }
    })
  }

  /**
   * Initializes the data binding for form object
   *
   * @param {Object} rowNode
   * @param {Object} data
   *
   * @returns {undefined}
   */
  function initializeDataBinding(rowNode, data) {
    var uiBindings = {};
    $.each(_.keys(data), function(i, element) {
      uiBindings['#' + element] = element;
    })
    $(rowNode).my({ui: uiBindings}, data);
  }

  /**
   * Generates the input tag id that will be used in the formData object
   *
   * @param {String} columnId
   *
   * @returns {String}
   */
  function generateInputFieldReference(columnId) {
    return 'colId-' + columnId;
  }

  /**
   * Appends aditional fields to form data object
   * @param {Object} cell
   * @param {String} columnId
   * @param {Object} formData
   *
   * @returns {undefined}
   */
  function appendNewElementToFormData(cell, columnId, formData) {
    if (!cell.repository_cell_id) {
      formData[generateInputFieldReference(columnId)] = undefined;
    }
  }
})(window);
