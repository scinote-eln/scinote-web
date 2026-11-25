/* global I18n */
import { jspreadsheet } from './jspreadsheet_vue.js';

export default {
  computed: {
    toolbar() {
      const component = this;

      const getActive = () => {
        if (component.$refs.spreadsheet.current) {
          return component.$refs.spreadsheet.current[0];
        }

        return null;
      };

      const getSelected = () => {
        const w = getActive();
        if (w) {
          return w.getSelected();
        }
        return [];
      };

      const getComputedStyle = (prop) => {
        const w = getActive();
        if (w && w.cursor) {
          const t = window.getComputedStyle(w.cursor);
          return t.getPropertyValue(prop);
        }
        return '';
      };

      const toolbarItems = (env) => {
        const existingItems = env.items;

        existingItems[0].content = '<i class="sn-icon sn-icon-undo"></i>';
        existingItems[1].content = '<i class="sn-icon sn-icon-redo"></i>';
        existingItems[2].content = '<i class="sn-icon sn-icon-export"></i>';
        existingItems[2].onclick = () => {
          jspreadsheet.render(getActive().parent.el, {
            filename: `${component.element.name}.xlsx`,
            onbeforerender: (spreadsheetConfig) => {
              spreadsheetConfig.worksheets[0].data.forEach((row, y) => {
                row.forEach((cell, x) => {
                  // replace semicolon in formulas with comma, to ensure Excel compatibility
                  if (typeof(cell) === 'string' && cell.startsWith('=')) {
                    spreadsheetConfig.worksheets[0].data[y][x] = cell.replace(/;/g, ',');
                  }

                  if (/=.*(?:'[^']+'|\[[^\]]+\]|[A-Za-z0-9_\-]+)!([A-Z]+\d+)/.test(cell)) {
                    spreadsheetConfig.worksheets[0].data[y][x] = this.$refs.spreadsheet.current[0].getValueFromCoords(x, y, true);
                  }
                });
              });
              return spreadsheetConfig;
            }
          });
        };
        existingItems[5].content = '<i class="sn-icon sn-icon-text-fields"></i>';

        existingItems[5].options = ['10px', '12px', '14px', '16px', '20px'];
        existingItems[5].data = ['10px', '12px', '14px', '16px', '20px'];
        existingItems[5].render = (e) => (`<span style="font-size: ${e}">${e.split('px')[0]}</span>`);

        existingItems[6].render = (e) => (`<i class="sn-icon sn-icon-align-horizontal-${e}"></i>`);
        existingItems[7].content = '<i class="sn-icon sn-icon-text-bold"></i>';
        existingItems[8].content = '<i class="sn-icon sn-icon-text-format"></i>';
        existingItems[9].content = '<i class="sn-icon sn-icon-color-fill"></i>';
        existingItems[10].render = (e) => (`<i class="sn-icon sn-icon-align-vertical-${e.split('_')[2]}"></i>`);
        existingItems[11].content = '<i class="sn-icon sn-icon-merge-cells"></i>';
        existingItems[11].onclick = () => {
          const w = getActive();
          if (w) {
            const h = w.getHighlighted();
            if (h && h.length) {
              if (w.records[h[0][1]][h[0][0]].merged) {
                this.mergeCellTitle = I18n.t('scinote.native_tables.unmerge_cell_title');
                this.mergeCellDescription = I18n.t('scinote.native_tables.unmerge_cell_description');
                this.mergeCellConfirm = I18n.t('scinote.native_tables.unmerge_cell_confirm');
                this.$nextTick(async () => {
                  const ok = await this.$refs.mergeCellModal.show();
                  if (ok) {
                    let cells = {};
                    h.forEach(element => {
                      cells[[component.integerToCharacter(element[0] + 1), element[1] + 1].join('')] = true;
                    });
                    w.removeMerge(cells);
                  }
                  this.mergeCellTitle = null;
                });
              } else {
                this.mergeCellTitle = I18n.t('scinote.native_tables.merge_cell_title');
                this.mergeCellDescription = I18n.t('scinote.native_tables.merge_cell_description');
                this.mergeCellConfirm = I18n.t('scinote.native_tables.merge_cell_confirm');
                this.$nextTick(async () => {
                  const ok = await this.$refs.mergeCellModal.show();
                  if (ok) {
                    h.forEach(element => {
                      w.updateSelectionFromCoords(element[0], element[1], element[2], element[3]);
                      w.setMerge();
                    });
                  }
                  this.mergeCellTitle = null;
                });
              }
            }
          }
        };

        existingItems[12].render = (e) => (`<i class="sn-icon sn-icon-${e.replace('_', '-')}"></i>`);
        existingItems.splice(14, 2); // Remove insert image and full screen
        existingItems.splice(8, 0, {
          content: '<i class="sn-icon sn-icon-text-Italic"></i>',
          tooltip: I18n.t('scinote.native_tables.italic'),
          onclick: (_a, _b, c) => {
            const w = getActive();
            if (w) {
              const current = getComputedStyle('font-style');
              const style = current === 'italic' ? '' : 'italic';
              const cells = getSelected();
              if (cells) {
                w.setStyle(cells, 'font-style', style);
              }
              if (style === 'italic') {
                c.classList.add('jss_toolbar_selected');
              } else {
                c.classList.remove('jss_toolbar_selected');
              }
            }
          },
          updateState: (_a, _b, c) => {
            const value = getComputedStyle('font-style');
            if (this.locked) {
              c.classList.add('jtoolbar-disabled');
            } else {
              c.classList.remove('jtoolbar-disabled');
            }

            if (value === 'italic') {
              c.classList.add('jss_toolbar_selected');
            } else {
              c.classList.remove('jss_toolbar_selected');
            }
          }
        });

        existingItems.splice(3, 0, {
          content: '<i class="sn-icon sn-icon-import"></i>',
          tooltip: I18n.t('scinote.native_tables.import'),
          onclick: () => {
            this.$refs.fileInput.click();
          },
          updateState: (_a, _b, c) => {
            if (this.isWellPlate || this.locked) {
              c.classList.add('jtoolbar-disabled');
            }
          }
        });

        // Add decimals button

        existingItems.splice(15, 0, {
          content: '<i class="sn-icon sn-icon-reset-cell"></i>',
          tooltip: I18n.t('scinote.native_tables.reset_cell'),
          onclick: () => {
            const w = getActive();
            const cells = getSelected();
            if (w && cells) {
              cells.forEach((cell) => {
                w.updateProperty(cell.x, cell.y, {
                  type: 'text',
                  mask: ''
                });
              });
            }
            component.debouncedUpdate();
          },
          updateState: (_a, _b, c) => {
            if (this.locked) {
              c.classList.add('jtoolbar-disabled');
            }
          }
        });

        function clearNotNumericCellContent(cell) {
          const w = getActive();
          // Clear content if no numbers before changing type
          const cellValue = w.getValueFromCoords(cell.x, cell.y);
          if (cellValue && !/[\d]/g.test(cellValue)) {
            w.setValueFromCoords(cell.x, cell.y, '');
          }
        }

        existingItems.splice(16, 0, {
          content: '<i class="sn-icon sn-icon-decimal-decrease"></i>',
          tooltip: I18n.t('scinote.native_tables.decimal_decrease'),
          onclick: () => {
            const w = getActive();
            const cells = getSelected();
            if (w && cells) {
              cells.forEach((cell) => {
                const property = w.getProperty(cell.x, cell.y);
                let decimalPlaces = 0;
                let mask = '0';
                if (property.type === 'numeric' && property.decimalPlaces) {
                  decimalPlaces = Math.max(0, property.decimalPlaces - 1);
                  mask = decimalPlaces === 0 ? '0' : '0.' + '0'.repeat(decimalPlaces);
                }

                clearNotNumericCellContent(cell); // Clear content if no numbers before changing type

                w.updateProperty(cell.x, cell.y, {
                    type: 'numeric',
                    mask: mask,
                    decimal: '.',
                    decimalPlaces: decimalPlaces,
                    disabledMaskOnEdition: false
                });
              });
            }
            component.debouncedUpdate();
          },
          updateState: (_a, _b, c) => {
            if (this.locked) {
              c.classList.add('jtoolbar-disabled');
            }
          }
        });

        existingItems.splice(17, 0, {
          content: '<i class="sn-icon sn-icon-decimal-increase"></i>',
          tooltip: I18n.t('scinote.native_tables.decimal_increase'),
          onclick: () => {
            const w = getActive();
            const cells = getSelected();
            if (w && cells) {
              cells.forEach((cell) => {
                const property = w.getProperty(cell.x, cell.y);
                let decimalPlaces = 1;
                let mask = '0.0';
                if (property.type === 'numeric' && property.decimalPlaces) {
                  decimalPlaces = property.decimalPlaces + 1;
                  mask = '0.' + '0'.repeat(decimalPlaces);
                }

                clearNotNumericCellContent(cell); // Clear content if no numbers before changing type

                w.updateProperty(cell.x, cell.y, {
                    type: 'numeric',
                    mask: mask,
                    decimal: '.',
                    decimalPlaces: decimalPlaces,
                    disabledMaskOnEdition: false
                });
              });
            }
            component.debouncedUpdate();
          },
          updateState: (_a, _b, c) => {
            if (this.locked) {
              c.classList.add('jtoolbar-disabled');
            }
          }
        });

        // prepend refresh button
        existingItems.unshift(
          {
            content: '<i class="sn-icon sn-icon-refresh"></i>',
            tooltip: I18n.t('scinote.native_tables.refresh'),
            onclick: () => {
              this.refresh();
            }
          }
        );

        return env;
      };
      return toolbarItems;
    }
  }
};
