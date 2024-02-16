/*
  Licensed under the MIT license
  Copyright (c) 2014 handsontable
*/
(function(Handsontable) {
  'use strict';

  // [MODIFICATION] (sci 2588)
  var formulasResults = {};
  // _!_MODIFICATION
  function HandsontableFormula() {

    var isFormula = function(value) {
      if (value) {
        if (value[0] === '=') {
          return true;
        }
      }

      return false;
    };

    // [MODIFICATION] (sci 2588)
    var beforeRender = function (isForced) {
          formulasResults = {};
          var data = this.getData();
          for (var i = 0; i < data.length; ++i) {
              for (var j = 0; j < data[i].length; ++j) {
                  var value = data[i][j];
                  if (value && value[0] === '=') {
                      var cellId = this.plugin.utils.translateCellCoords({row: i, col: j});
                      this.plugin.matrix.removeItem(cellId);
                  }
              }
          }
    };
    // _!_MODIFICATION

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

          // [MODIFICATION] (sci 2588)
          if (formulasResults[cellId] === undefined) {
          // _!_MODIFICATION

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
        // [MODIFICATION] (sci 2588)
        } else {
          var newValue = formulasResults[cellId];

          error = newValue.error;
          result = newValue.result;

          value = error || result;
        }
        // _!_MODIFICATION
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

      var rlength = data.length, // rows
          clength = data[0].length, //cols
          r = index.row % rlength,
          c = index.col % clength,
          value = data[r][c],
          delta = 0;

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

      } /* else { // other value

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

      } */

      return {
        value: value,
        iterators: iterators
      };
    };

    var afterCreateRow = function(row, amount) {

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
          //
          // [MODIFICATION] (sci 2588)
          // Previously: "cellValue: instance.getDataAtCell"
          //
          cellValue: function(row, col){
              var value = instance.getDataAtCell(row, col);
              if (value && value[0] === '=') {
                  var formula = value.substr(1).toUpperCase();
                  var cellId = instance.plugin.utils.translateCellCoords({row: row, col: col});
                  var item = instance.plugin.matrix.getItem(cellId);

                  if (!item) {
                      item = instance.plugin.matrix.addItem({id: cellId, formula: formula});
                  } else {
                      item = instance.plugin.matrix.updateItem({id: cellId, formula: formula});
                  }
                  // parse formula
                  var newValue = instance.plugin.parse(formula, {row: row, col: col, id: cellId});
                  // cache result
                  formulasResults[cellId] = newValue;
                  // update item value and error
                  instance.plugin.matrix.updateItem(item, {formula: formula, value: newValue.result, error: newValue.error});

                  value = newValue.error || newValue.result;
              }
              return value;
          }
          // _!_MODIFICATION
        };

        instance.plugin = new ruleJS();
        instance.plugin.init();
        instance.plugin.custom = custom;

        Handsontable.cellTypes.registerCellType('formula', {
          editor: Handsontable.editors.TextEditor,
          renderer: formulaRenderer
        });

        Handsontable.cellTypes.text.renderer = formulaRenderer;
        Handsontable.cellTypes.numeric.renderer = formulaRenderer;

        // [MODIFICATION] (sci 2588)
        // This hook is new
        instance.addHook('beforeRender', beforeRender);
        // _!_MODIFICATION
        instance.addHook('afterChange', afterChange);
        instance.addHook('beforeAutofillInsidePopulate', beforeAutofillInsidePopulate);

        instance.addHook('afterCreateRow', afterCreateRow);
        instance.addHook('afterCreateCol', afterCreateCol);

      } else {
        // [MODIFICATION] (sci 2588)
        // This hook is new
        instance.removeHook('beforeRender', beforeRender);
        // _!_MODIFICATION
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
