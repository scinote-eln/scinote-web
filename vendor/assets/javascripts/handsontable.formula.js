(function(Handsontable) {
  'use strict';

  function HandsontableFormula() {

    var isFormula = function(value) {
      if (value) {
        if (value[0] === '=') {
          return true;
        }
      }

      return false;
    };

    var formulaRenderer = function(instance, TD, row, col, prop, value, cellProperties) {
      if (instance.formulasEnabled && isFormula(value)) {
        // translate coordinates into cellId
        var cellId = instance.plugin.utils.translateCellCoords({
              row: row,
              col: col
            }),
            prevFormula = null,
            formula = null,
            needUpdate = false,
            error, result;

        if (!cellId) {
          return;
        }

        // get cell data
        var item = instance.plugin.matrix.getItem(cellId);

        if (item) {

          needUpdate = !! item.needUpdate;

          if (item.error) {
            prevFormula = item.formula;
            error = item.error;

            if (needUpdate) {
              error = null;
            }
          }
        }

        // check if typed formula or cell value should be recalculated
        if ((value && value[0] === '=') || needUpdate) {

          formula = value.substr(1).toUpperCase();

          if (!error || formula !== prevFormula) {

            var currentItem = item;

            if (!currentItem) {

              // define item to rulesJS matrix if not exists
              item = {
                id: cellId,
                formula: formula
              };

              // add item to matrix
              currentItem = instance.plugin.matrix.addItem(item);
            }

            // parse formula
            var newValue = instance.plugin.parse(formula, {
              row: row,
              col: col,
              id: cellId
            });

            // check if update needed
            needUpdate = (newValue.error === '#NEED_UPDATE');

            // update item value and error
            instance.plugin.matrix.updateItem(currentItem, {
              formula: formula,
              value: newValue.result,
              error: newValue.error,
              needUpdate: needUpdate
            });

            error = newValue.error;
            result = newValue.result;

            // update cell value in hot
            value = error || result;
          }
        }

        if (error) {
          // clear cell value
          if (!value) {
            // reset error
            error = null;
          } else {
            // show error
            value = error;
          }
        }

        // change background color
        if (instance.plugin.utils.isSet(error)) {
          Handsontable.Dom.addClass(TD, 'formula-error');
        } else if (instance.plugin.utils.isSet(result)) {
          Handsontable.Dom.removeClass(TD, 'formula-error');
          Handsontable.Dom.addClass(TD, 'formula');
        }
      }

      // apply changes
      if (cellProperties.type === 'numeric') {
        numericCell.renderer.apply(this, [instance, TD, row, col, prop, value, cellProperties]);
      } else {
        textCell.renderer.apply(this, [instance, TD, row, col, prop, value, cellProperties]);
      }
    };

    var afterChange = function(changes, source) {
      var instance = this;

      if (!instance.formulasEnabled) {
        return;
      }

      if (source === 'edit' || source === 'undo' || source === 'autofill') {

        var rerender = false;

        changes.forEach(function(item) {

          var row = item[0],
              col = item[1],
              prevValue = item[2],
              value = item[3];

          var cellId = instance.plugin.utils.translateCellCoords({
            row: row,
            col: col
          });

          // if changed value, all references cells should be recalculated
          if (value[0] !== '=' || prevValue !== value) {
            instance.plugin.matrix.removeItem(cellId);

            // get referenced cells
            var deps = instance.plugin.matrix.getDependencies(cellId);

            // update cells
            deps.forEach(function(itemId) {
              instance.plugin.matrix.updateItem(itemId, {
                needUpdate: true
              });
            });

            rerender = true;
          }
        });

        if (rerender) {
          instance.render();
        }
      }
    };

    var beforeAutofillInsidePopulate = function(index, direction, data, deltas, iterators, selected) {
      var instance = this;

      var r = index.row,
          c = index.col,
          value = data[r][c],
          delta = 0,
          rlength = data.length, // rows
          clength = data ? data[0].length : 0; //cols

      if (value[0] === '=') { // formula

        if (['down', 'up'].indexOf(direction) !== -1) {
          delta = rlength * iterators.row;
        } else if (['right', 'left'].indexOf(direction) !== -1) {
          delta = clength * iterators.col;
        }

        return {
          value: instance.plugin.utils.updateFormula(value, direction, delta),
          iterators: iterators
        }

      } else { // other value

        // increment or decrement  values for more than 2 selected cells
        if (rlength >= 2 || clength >= 2) {

          var newValue = instance.plugin.helper.number(value),
              ii,
              start;

          if (instance.plugin.utils.isNumber(newValue)) {

            if (['down', 'up'].indexOf(direction) !== -1) {

              delta = deltas[0][c];

              if (direction === 'down') {
                newValue += (delta * rlength * iterators.row);
              } else {

                ii = (selected.row - r) % rlength;
                start = ii > 0 ? rlength - ii : 0;

                newValue = instance.plugin.helper.number(data[start][c]);

                newValue += (delta * rlength * iterators.row);

                // last element in array -> decrement iterator
                // iterator cannot be less than 1
                if (iterators.row > 1 && (start + 1) === rlength) {
                  iterators.row--;
                }
              }

            } else if (['right', 'left'].indexOf(direction) !== -1) {
              delta = deltas[r][0];

              if (direction === 'right') {
                newValue += (delta * clength * iterators.col);
              } else {

                ii = (selected.col - c) % clength;
                start = ii > 0 ? clength - ii : 0;

                newValue = instance.plugin.helper.number(data[r][start]);

                newValue += (delta * clength * (iterators.col || 1));

                // last element in array -> decrement iterator
                // iterator cannot be less than 1
                if (iterators.col > 1 && (start + 1) === clength) {
                  iterators.col--;
                }
              }
            }

            return {
              value: newValue,
              iterators: iterators
            }
          }
        }

      }

      return {
        value: value,
        iterators: iterators
      };
    };

    var afterCreateRow = function(row, amount, auto) {
      if (auto) {
        return;
      }

      var instance = this;

      var selectedRow = instance.plugin.utils.isArray(instance.getSelected()) ? instance.getSelected()[0] : undefined;

      if (instance.plugin.utils.isUndefined(selectedRow)) {
        return;
      }

      var direction = (selectedRow >= row) ? 'before' : 'after',
          items = instance.plugin.matrix.getRefItemsToRow(row),
          counter = 1,
          changes = [];

      items.forEach(function(id) {
        var item = instance.plugin.matrix.getItem(id),
            formula = instance.plugin.utils.changeFormula(item.formula, 1, {
              row: row
            }), // update formula if needed
            newId = id;

        if (formula !== item.formula) { // formula updated

          // change row index and get new coordinates
          if ((direction === 'before' && selectedRow <= item.row) || (direction === 'after' && selectedRow < item.row)) {
            newId = instance.plugin.utils.changeRowIndex(id, counter);
          }

          var cellCoords = instance.plugin.utils.cellCoords(newId);

          if (newId !== id) {
            // remove current item from matrix
            instance.plugin.matrix.removeItem(id);
          }

          // set updated formula in new cell
          changes.push([cellCoords.row, cellCoords.col, '=' + formula]);
        }
      });

      if (items) {
        instance.plugin.matrix.removeItemsBelowRow(row);
      }

      if (changes) {
        instance.setDataAtCell(changes);
      }
    };

    var afterCreateCol = function(col) {
      var instance = this;

      var selectedCol = instance.plugin.utils.isArray(instance.getSelected()) ? instance.getSelected()[1] : undefined;

      if (instance.plugin.utils.isUndefined(selectedCol)) {
        return;
      }

      var items = instance.plugin.matrix.getRefItemsToColumn(col),
          counter = 1,
          direction = (selectedCol >= col) ? 'before' : 'after',
          changes = [];

      items.forEach(function(id) {

        var item = instance.plugin.matrix.getItem(id),
            formula = instance.plugin.utils.changeFormula(item.formula, 1, {
              col: col
            }), // update formula if needed
            newId = id;

        if (formula !== item.formula) { // formula updated

          // change col index and get new coordinates
          if ((direction === 'before' && selectedCol <= item.col) || (direction === 'after' && selectedCol < item.col)) {
            newId = instance.plugin.utils.changeColIndex(id, counter);
          }

          var cellCoords = instance.plugin.utils.cellCoords(newId);

          if (newId !== id) {
            // remove current item from matrix if id changed
            instance.plugin.matrix.removeItem(id);
          }

          // set updated formula in new cell
          changes.push([cellCoords.row, cellCoords.col, '=' + formula]);
        }
      });

      if (items) {
        instance.plugin.matrix.removeItemsBelowCol(col);
      }

      if (changes) {
        instance.setDataAtCell(changes);
      }
    };

    var formulaCell = {
      renderer: formulaRenderer,
      editor: Handsontable.editors.TextEditor,
      dataType: 'formula'
    };

    var textCell = {
      renderer: Handsontable.renderers.TextRenderer,
      editor: Handsontable.editors.TextEditor
    };

    var numericCell = {
      renderer: Handsontable.renderers.NumericRenderer,
      editor: Handsontable.editors.NumericEditor
    };

    this.init = function() {
      var instance = this;
      instance.formulasEnabled = !! instance.getSettings().formulas;

      if (instance.formulasEnabled) {

        var custom = {
          cellValue: instance.getDataAtCell
        };

        instance.plugin = new ruleJS();
        instance.plugin.init();
        instance.plugin.custom = custom;

        Handsontable.cellTypes['formula'] = formulaCell;

        Handsontable.TextCell.renderer = formulaRenderer;
        Handsontable.NumericCell.renderer = formulaRenderer;

        instance.addHook('afterChange', afterChange);
        instance.addHook('beforeAutofillInsidePopulate', beforeAutofillInsidePopulate);

        instance.addHook('afterCreateRow', afterCreateRow);
        instance.addHook('afterCreateCol', afterCreateCol);

      } else {
        instance.removeHook('afterChange', afterChange);
        instance.removeHook('beforeAutofillInsidePopulate', beforeAutofillInsidePopulate);

        instance.removeHook('afterCreateRow', afterCreateRow);
        instance.removeHook('afterCreateCol', afterCreateCol);
      }
    };
  }

  var htFormula = new HandsontableFormula();

  Handsontable.hooks.add('beforeInit', htFormula.init);

  Handsontable.hooks.add('afterUpdateSettings', function() {
    htFormula.init.call(this, 'afterUpdateSettings')
  });

})(Handsontable);