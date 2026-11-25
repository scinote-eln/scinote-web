/* global I18n */
import { jspreadsheet } from './jspreadsheet_vue.js';

export default {
  computed: {
    contextMenu() {
      const component = this;
      const menuItems = function(_o, _x, _y, _e, items) {
        let existingItems = items;

        const spreadsheet = component.$refs.spreadsheet.current[0];
        const selectedCells = spreadsheet.getSelected();

        const getActive = () => {
          if (component.$refs.spreadsheet.current) {
            return component.$refs.spreadsheet.current[0];
          }

          return null;
        };

        if (component.locked) {
          existingItems = [];
        } else {
          existingItems = existingItems.map((item) => {
            item.icon = null;

            if (item.title === 'Rename this column') {
              item.onclick = () => {
                const columnNumber = spreadsheet.getSelected()[0].x;
                component.openRenameColumnModal = true;
                component.columnToRename = columnNumber;
                component.renameColumnName = spreadsheet.getProperty(columnNumber).title;
              };
            }

            if (item.title === 'Save as') {
              item.onclick = () => {
                jspreadsheet.render(getActive().parent.el, {
                  filename: `${component.element.name}.xlsx`
                });
              };
            }

            if (item.title === 'Rename this worksheet') {
              item.onclick = () => {
                component.openRenameWorksheetModal = true;
                component.renameWorksheetName = spreadsheet.getWorksheetName(0);
              };
            }

            return item;
          });

          let separatorCounter = 0;
          existingItems = existingItems.filter((item) => {
            if (item.title === 'About' || item.title === 'Add notes') {
              return false;
            }

            if (item.title === 'Cut') {
              let anySa = false;
              selectedCells.forEach((cell) => {
                const property = spreadsheet.getProperty(cell.x, cell.y);
                if (property.type === 'sa' || property.type?.name === 'sa') {
                  anySa = true;
                }
              });

              if (anySa) {
                return false;
              }
            }

            if (item.type === 'line') {
              separatorCounter += 1;
              if (separatorCounter === 1 && component.isWellPlate) return false;
              if (separatorCounter === 2) return false;
              return true;
            }

            return true;
          });


          if (selectedCells.length > 0) {
            // Smart annotation

            const firstCellProperty = spreadsheet.getProperty(selectedCells[0]?.x, selectedCells[0]?.y);
            const isSA = (firstCellProperty?.type?.name || firstCellProperty?.type) === 'sa';
            const saOptionTitle = isSA ? I18n.t('scinote.native_tables.edit_sa') : I18n.t('scinote.native_tables.add_sa');
            const cellIsLocked = firstCellProperty?.readOnly;

            if (!cellIsLocked || isSA) {
              existingItems.push({
                title: saOptionTitle,
                onclick: () => {
                  const selectedCell = selectedCells[0];
                  component.selectedCell = selectedCell;
                  component.openSmartAnnotationModal = true;
                  component.smartAnnotationMode = firstCellProperty.type?.name === 'sa' ? 'edit' : 'add';

                  component.smartAnnotationCell = spreadsheet.getValueFromCoords(selectedCell.x, selectedCell.y);
                  spreadsheet.resetSelection();
                }
              });
              if (isSA) {
                existingItems.push({
                  title: I18n.t('scinote.native_tables.delete_sa'),
                  onclick: () => {
                    spreadsheet.setProperty(selectedCells[0].x, selectedCells[0].y, {
                      type: null,
                      readOnly: false
                    });
                    spreadsheet.updateCell(selectedCells[0].x, selectedCells[0].y, '', true);
                    component.updateTable();
                  }
                });
              }
            }

            existingItems.push({
              title: I18n.t('scinote.native_tables.lock_cell'),
              onclick: () => {
                selectedCells.forEach((cell) => {
                  const property = spreadsheet.getProperty(cell.x, cell.y);
                  if (property.type !== 'sa') {
                    spreadsheet.setReadOnly([component.integerToCharacter(cell.x + 1), cell.y + 1].join(''), true);
                  }
                });
                component.debouncedUpdate();
              }
            });

            existingItems.push({
              title: I18n.t('scinote.native_tables.unlock_cell'),
              onclick: () => {
                selectedCells.forEach((cell) => {
                  const property = spreadsheet.getProperty(cell.x, cell.y);
                  if (property.type !== 'sa') {
                    spreadsheet.setReadOnly([component.integerToCharacter(cell.x + 1), cell.y + 1].join(''), false);
                  }
                });
                component.debouncedUpdate();
              }
            });
          }
        }

        existingItems.push({
          title: I18n.t('scinote.native_tables.supported_formulas'),
          onclick: () => {
            window.open(component.formulasHelpUrl, '_blank');
          }
        });

        return existingItems;
      };
      return menuItems;
    }
  }
};
