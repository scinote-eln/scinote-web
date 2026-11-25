<template>
  <div v-if="renderContainer" ref="tableContainer" class="content__table-container pr-8"
    :data-e2e="`e2e-CO-${dataE2e}-${element.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}`">
    <div class="sci-divider my-6" v-if="!inRepository"></div>
    <div :class="{'!bg-sn-background-brittlebush p-4': element.archived}">
      <div class="table-header h-9 flex rounded mb-3 items-center gap-2 relative w-full group/table-header" :class="{ 'editing-name': editingName, 'locked': locked }">
        <div v-if="!locked || element.name" :key="reloadHeader"
            class="text-ellipsis whitespace-nowrap my-1 font-bold"
            :class="{'grow': !this.element.archived,
                     'pointer-events-none': locked}">
          <InlineEdit
            :value="element.name"
            :characterLimit="255"
            :placeholder="i18n.t('protocols.steps.table.table_name')"
            :allowBlank="false"
            :autofocus="editingName"
            :attributeName="`${i18n.t('Table')} ${i18n.t('name')}`"
            :dataE2e="`${dataE2e}-${element.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}`"
            @editingEnabled="enableNameEdit"
            @editingDisabled="disableNameEdit"
            @update="updateName"
          />
        </div>
        <template v-if="this.element.archived">
          <div class="sci-tag bg-sn-alert-brittlebush pointer-events-none text-sn-black">
            {{ i18n.t('my_modules.results.archived') }}
            <span class="sn-icon sn-icon-archived"></span>
          </div>
          <span class="text-xs ">
            {{ i18n.t('protocols.steps.timestamp_archived', {
              date: this.element.archived_on,
              user: this.element.archived_by
            }) }}
          </span>
        </template>
        <LockedTag v-if="element.locked" />
        <div class="ml-auto flex items gap-4">
          <button
            v-if="this.element.urls.restore_url"
            :class="['btn icon-btn btn-light', `e2e-BT-${this.e2eClass}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}-options-restore`]"
            class="btn icon-btn btn-light"
            @click="confirmingRestore = true"
            :title="i18n.t('general.restore')"
            :data-e2e="`e2e-BT-${this.dataE2e}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-restore`"
          >
            <i class="sn-icon sn-icon-restore"></i>
          </button>
          <button
            v-if="this.element.archived && this.element.urls.delete_url"
            :class="['btn icon-btn btn-light', `e2e-BT-${this.e2eClass}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}-options-delete`]"
            @click="showDeleteModal"
            :title="i18n.t('general.delete')"
            :data-e2e="`e2e-BT-${this.dataE2e}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-delete`"
          >
            <i class="sn-icon sn-icon-delete"></i>
          </button>
          <MenuDropdown
            v-if="inRepository || !this.element.locked"
            class="ml-auto"
            :listItems="this.actionMenu"
            :btnClasses="'btn btn-light icon-btn btn-sm'"
            :position="'right'"
            :btnIcon="'sn-icon sn-icon-more-hori'"
            :dataE2e="`e2e-DD-${dataE2e}-${element.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}-options`"
            @edit="enableNameEdit"
            @duplicate="duplicateElement"
            @move="showMoveModal"
            @archive="showArchiveModal"
            @delete="showDeleteModal"
          ></MenuDropdown>
        </div>
      </div>
      <div ref="spreadsheetContainer" class="table-body group/table-body relative border-solid border-transparent relative"
          :class="{'edit border-sn-light-grey': editingTable, 'view': !editingTable, 'locked': !element.urls.update_url}"
          tabindex="0"
          :data_e2e="`e2e-TB-${dataE2e}-${element.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}`"
      >
        <div v-if="waitingForCrossTableFormulas" class="w-[110%] opacity-80 h-full bg-sn-white absolute top-0 left-0 z-50 flex items-center">
          <div class="sci-loader"></div>
        </div>
        <div v-if="sheetNameNotUnique" class="sci-toast sci-toast-warning mb-3">
          {{ i18n.t('scinote.native_tables.sheet_name_not_unique') }}
        </div>
        <Spreadsheet
          ref="spreadsheet"
          :key="tableKey"
          :license="license"
          :allowExport="true"
          :tabs="{
              allowCreate: false,
              allowChangePosition: false
          }"
          :editable="!locked"
          :onchange="handleOnChange"
          :oninsertrow="debouncedUpdate"
          :oninsertcolumn="debouncedUpdate"
          :ondeletecolumn="debouncedUpdate"
          :ondeleterow="debouncedUpdate"
          :onmoverow="debouncedUpdate"
          :onresizerow="debouncedUpdate"
          :onresizecolumn="debouncedUpdate"
          :onmovecolumn="debouncedUpdate"
          :onchangestyle="debouncedUpdate"
          :onmerge="debouncedUpdate"
          :onbeforeformula="handleFormula"
          :toolbar="toolbar"
          :contextMenu="contextMenu"
          :onload="onloadTable"
          :extensions="extensions"
          :oneditionstart="editingStarted"
          :oneditionend="editingEnded"
          :allowDeleteWorksheet="false"
          :allowMoveWorksheet="false"
        >
          <Worksheet
            :data="tableData"
            :style="element.metadata.cells_style"
            :mergeCells="element.metadata.cells_merge"
            :worksheetName="element.metadata.sheet_name"
            :tableOverflow="true"
            :columns="columnsConfig"
            :rows="rowsConfig"
            :minDimensions="minDimensions"
            resize="vertical"
            :virtualizationX="false"
            :virtualizationY="false"
            :allowInsertColumn="!isWellPlate"
            :allowInsertRow="!isWellPlate"
            :allowDeleteColumn="!isWellPlate"
            :allowDeleteRow="!isWellPlate"
            :allowManualInsertColumn="!isWellPlate"
            :allowManualInsertRow="!isWellPlate"
            :allowRenameColumn="!isWellPlate"
            :columnDrag="!isWellPlate"
            :rowDrag="!isWellPlate"
          />
        </Spreadsheet>
      </div>
      <div class="text-xs text inline-flex items-center h-8 text-sn-grey ">
        <span v-if="!locked" :dataE2e="`e2e-TX-${dataE2e}-${element.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}-editMessage`">
          {{ i18n.t('scinote.native_tables.edit_message')}}
        </span>
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" :inRepository="inRepository" @confirm="deleteElement" @cancel="closeDeleteModal"/>
    <RestoreModal v-if="confirmingRestore"
                  :parentType="element.parent_type"
                  :element="'table'"
                  @confirm="restoreElement"
                  @close="confirmingRestore = false"/>
    <ArchiveModal v-if="confirmingArchive" @confirm="archiveElement" @close="closeArchiveModal"/>
    <tableNameModal v-if="nameModalOpen" :element="element" @update="updateEmptyName" @cancel="nameModalOpen = false" />
    <moveElementModal v-if="movingElement"
                      :parent_type="element.parent_type"
                      :targets_url="element.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
    <TableSmartAnnotationModal
      v-if="openSmartAnnotationModal"
      @confirm="saveSmartAnnotationToCell"
      @close="openSmartAnnotationModal = false"
      :sa_data="smartAnnotationCell"
      :smartAnnotationMode="smartAnnotationMode"
    />
    <TableColumnRenameModal
      v-if="openRenameColumnModal"
      @confirm="changeColumnName"
      @close="openRenameColumnModal = false"

      :column_name="renameColumnName"
    />
    <TableWorksheetRenameModal
      v-if="openRenameWorksheetModal"
      @confirm="changeWorksheetName"
      @close="openRenameWorksheetModal = false"
      :worksheet_name="renameWorksheetName"
    />
    <ConfirmationModal
      v-if="mergeCellTitle"
      :title="mergeCellTitle"
      :description="mergeCellDescription"
      :confirmText="mergeCellConfirm"
      confirmClass="btn btn-primary"
      ref="mergeCellModal"
    ></ConfirmationModal>

    <ConfirmationModal
      :title="i18n.t('scinote.native_tables.import_modal_title')"
      :description="i18n.t('scinote.native_tables.import_modal_description')"
      :confirmText="i18n.t('scinote.native_tables.import_modal_confirm')"
      confirmClass="btn btn-primary"
      ref="importXlsxModal"
    ></ConfirmationModal>

    <TableImportErrorModal
      v-if="importError"
      @close="importError = false"/>

  <input
    type="file"
    name="file"
    ref="fileInput"
    @change="loadFile"
    style="display: none"
    accept=".xlsx"
  />
  </div>
</template>

<script>

import { Spreadsheet, Worksheet, jspreadsheet } from './jspreadsheet_vue.js';
import parser from "@jspreadsheet/parser";
import render from '@jspreadsheet/render';
import formula from "@jspreadsheet/formula-pro";
import DeleteMixin from './mixins/delete.js';
import MoveMixin from './mixins/move.js';
import DuplicateMixin from './mixins/duplicate.js';
import ArchiveMixin from './mixins/archive.js';
import deleteElementModal from './modal/delete.vue';
import InlineEdit from '../inline_edit.vue';
import TableNameModal from './modal/table_name.vue';
import moveElementModal from './modal/move.vue';
import MenuDropdown from '../menu_dropdown.vue';
import TableToolbaMixin from './table_toolbar_mixin.js';
import TableContextMenuMixin from './table_context_menu_mixin.js';
import TableSmartAnnotationModal from './table_smart_annotation_modal.vue';
import ConfirmationModal from '../../shared/confirmation_modal.vue';
import TableColumnRenameModal from './table_column_rename_modal.vue';
import TableWorksheetRenameModal from './table_worksheet_rename_modal.vue';
import TableImportErrorModal from './table_import_error_modal.vue';
import ArchiveModal from './modal/archive_table.vue';
import RestoreModal from './modal/restore_element.vue';
import { debounce } from '../debounce.js';
import tooltipMixin from '../../mixins/tooltipMixin.js';
import LockedTag from '../snippets/locked_tag.vue';

export default {
  name: 'ContentTable',
  components: {
    deleteElementModal,
    InlineEdit,
    TableNameModal,
    moveElementModal,
    MenuDropdown,
    Spreadsheet,
    Worksheet,
    TableSmartAnnotationModal,
    ConfirmationModal,
    TableColumnRenameModal,
    TableWorksheetRenameModal,
    TableImportErrorModal,
    ArchiveModal,
    RestoreModal,
    LockedTag
  },
  mixins: [
    DeleteMixin,
    DuplicateMixin,
    MoveMixin,
    TableToolbaMixin,
    TableContextMenuMixin,
    ArchiveMixin,
    tooltipMixin
  ],
  props: {
    element: {
      type: Object,
      required: true
    },
    inRepository: {
      type: Boolean,
      required: true
    },
    reorderElementUrl: {
      type: String
    },
    isNew: {
      type: Boolean, default: false
    },
    assignableMyModuleId: {
      type: Number,
      required: false
    },
    dataE2e: {
      type: String,
      default: ''
    },
    e2eClass: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      tableData: [],
      editingName: false,
      editingTable: false,
      editingCell: false,
      tableObject: null,
      nameModalOpen: false,
      reloadHeader: 0,
      updatingTableData: false,
      selectedCell: null,
      openSmartAnnotationModal: false,
      smartAnnotationMode: 'add',
      smartAnnotationCell: null,
      mergeCellTitle: null,
      mergeCellDescription: '',
      mergeCellConfirm: '',
      openRenameColumnModal: false,
      columnToRename: null,
      renameColumnName: '',
      debouncedUpdate: null,
      openRenameWorksheetModal: false,
      renameWorksheetName: '',
      isWellPlate: false,
      formulasHelpUrl: '',
      tableLoaded: false,
      importError: false,
      tableKey: 0,
      editingTable: false,
      waitingForCrossTableFormulas: false,
      updatingTableData: false,
      confirmingArchive: false,
      confirmingRestore: false,
      computedCells: [],
      extensions: {
        render: render,
        formula: formula,
        parser: parser
      },
      renderContainer: true
    };
  },
  computed: {
    sheetNameNotUnique() {
      return this.element.sheet_name_not_unique;
    },
    locked() {
      return !this.element.urls.update_url;
    },
    minDimensions() {
      return [this.tableData[0].length, this.tableData.length];
    },
    columnsConfig() {
      const columnsSize = this.element.metadata.columns_size || [];

      return this.tableData[0].map((_, index) => {
        return {
          wrap: true,
          width: columnsSize[index],
          // Set title if it's a well plate
          ...(this.isWellPlate && { title: index + 1 })
        };
      });
    },
    rowsConfig() {
      const rowsSize = this.element.metadata.rows_size || {};

      return this.tableData.map((_, index) => {
        return {
          ...(rowsSize[index] && { height: rowsSize[index] }),
          // Set title if it's a well plate (A, B, C, etc.)
          ...(this.isWellPlate && { title: this.integerToCharacter(index + 1) })
        };
      });
    },
    actionMenu() {
      const menu = [];
      if (this.element.urls.update_url) {
        menu.push({
          text: I18n.t('general.edit'),
          emit: 'edit',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-edit`,
          e2e_class: `e2e-BT-${this.e2eClass}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}-options-edit`
        });
      }
      if (this.element.urls.duplicate_url) {
        menu.push({
          text: I18n.t('general.duplicate'),
          emit: 'duplicate',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-duplicate`,
          e2e_class: `e2e-BT-${this.e2eClass}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}-options-duplicate`
        });
      }
      if (this.element.urls.move_targets_url) {
        menu.push({
          text: I18n.t('general.move'),
          emit: 'move',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-move`,
          e2e_class: `e2e-BT-${this.e2eClass}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}-options-move`
        });
      }

      if (this.element.urls.archive_url) {
        menu.push({
          text: I18n.t('general.archive'),
          emit: 'archive',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-archive`,
          e2e_class: `e2e-BT-${this.e2eClass}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}-options-archive`
        });
      }

      if (!this.element.archived && this.element.urls.delete_url) {
        menu.push({
          text: I18n.t('general.delete'),
          emit: 'delete',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-delete`,
          e2e_class: `e2e-BT-${this.e2eClass}-${this.element.metadata.plateTemplate ? 'wellPlate' : 'table'}-options-delete`
        });
      }

      return menu;
    },
    hasCrossTableReferences() {
      return /=.*(?:'[^']+'|\[[^\]]+\]|[A-Za-z0-9_\-]+)!([A-Z]+\d+)/.test(this.element.contents);
    }
  },
  created() {
    this.initialize();
  },
  mounted() {
    window.addEventListener('click', this.handleSaPopover);
    if (this.sheetNameNotUnique) this.showSheetNameErrorModal();
  },
  beforeUnmount() {
    this.cleanup();
  },
  methods: {
    initialize() {
      window.loadingTablesCount = (window.loadingTablesCount || 0) + 1;

      this.formulasHelpUrl = document.querySelector('meta[name="native-tables-formulas-url"]').getAttribute('content');
      this.license = document.querySelector('meta[name="jspreadsheet-key"]').getAttribute('content');
      this.tableData = JSON.parse(this.element.contents).data;
      this.isWellPlate = this.element.metadata.plateTemplate;
      this.computedCells = this.element.metadata.cells;
      window.addEventListener('resize', this.updateViewport);

      this.debouncedUpdate = debounce(() => {
        // Do not send any updates while the table is waiting for cross-table formulas
        if (this.waitingForCrossTableFormulas) return;

        this.updateTable();
        this.renderSmartAnnotations();
        this.$emit('update', this.element, false, () => {});
        this.editingTable = false;
      }, 1000);

      this.beforeVisitHandler = (event) => {
        if (this.editingTable) {
          event.preventDefault();
          this.debouncedUpdate();

          setTimeout(() => {
            Turbolinks.visit(event.data.url)
          }, 1200);
        }
      };
      window.addEventListener('turbolinks:before-visit', this.beforeVisitHandler);

      if (this.hasCrossTableReferences) {
        this.waitingForCrossTableFormulas = true;
        this.crossTableHandler = this.handleCrossTableReferences.bind(this);
        window.addEventListener('jspreadsheet-tables-loaded', this.crossTableHandler);
      }
    },
    cleanup() {
      window.removeEventListener('resize', this.updateViewport);
      window.removeEventListener('click', this.handleSaPopover);
      window.removeEventListener('turbolinks:before-visit', this.beforeVisitHandler);

      if (this.crossTableHandler) {
        window.removeEventListener('jspreadsheet-tables-loaded', this.crossTableHandler);
      }

      if (this.$refs.spreadsheet.current) {
        const spreadsheet = this.$refs.spreadsheet.current[0].parent;

        // The jspreadsheet instance is shared across pages (see jspreadsheet_vue.js), and destroy()
        // doesn't clear its global focus and formula picker state. If they still point at this table, the
        // next table's clicks would be routed to this destroyed one, so release them here.
        const pickerSession = jspreadsheet.picker.hasEvent(false);
        if (pickerSession?.worksheet?.parent === spreadsheet) {
          jspreadsheet.picker.cancel();
        }
        if (jspreadsheet.current?.parent === spreadsheet) {
          jspreadsheet.current = null;
        }

        // destroy() only cleans up the DOM and element listeners when given the container element,
        // not the spreadsheet instance
        jspreadsheet.destroy(this.$refs.spreadsheet.el);
      }
    },
    refresh() {
      this.renderContainer = false;
      this.cleanup();

      this.$nextTick(() =>
        {
          this.initialize();
          this.renderContainer = true;
        }
      )
    },
    showArchiveModal() {
      if (this.hasCrossTableReferences === true) {
        this.confirmingArchive = true;
      } else {
        this.archiveElement();
      }
    },
    showSheetNameErrorModal() {
      HelperModule.showErrorModal(
        this.i18n.t('scinote.native_tables.sheet_name_not_unique_modal.title'),
        this.i18n.t('scinote.native_tables.sheet_name_not_unique_modal.content')
      )
    },
    handleSaPopover() {
      this.$nextTick(() => {
        $('.popover').popover("hide");
      });
    },
    handleCrossTableReferences() {
      if (this.waitingForCrossTableFormulas && this.$refs.spreadsheet?.current?.[0]) {
        const spreadsheet = this.$refs.spreadsheet.current[0];

        this.$nextTick(() => {
          this.refreshFormulas();
          this.updateComputedCells();
          this.renderSmartAnnotations();

          this.waitingForCrossTableFormulas = false;
        });
      }
    },
    updateComputedCells() {
      if (!this.$refs.spreadsheet?.current?.[0]) return;

      const spreadsheet = this.$refs.spreadsheet.current[0];
      const computedCells = [];

      // Only update cells with formulas
      this.tableData.forEach((row, rowIndex) => {
        row.forEach((cell, columnIndex) => {
          const tableCellProperty = spreadsheet.getProperty(columnIndex, rowIndex);
          if ((typeof cell === 'string' && cell.startsWith('=')) || tableCellProperty.type === 'numeric') {
            computedCells.push({
              col: columnIndex,
              row: rowIndex,
              calculated: spreadsheet.getValueFromCoords(columnIndex, rowIndex, true)
            });
          }
        });
      });

      this.computedCells = computedCells;
    },
    refreshFormulas() {
      const worksheet = this.$refs.spreadsheet.current[0];
      worksheet.parent.config.editable = true;

      this.tableData.forEach((row, rowIndex) => {
        row.forEach((cell, columnIndex) => {
          if (typeof cell === 'string' && cell.startsWith('=')) {
            const originalFormula = cell;
            worksheet.setValueFromCoords(columnIndex, rowIndex, '', true);
            worksheet.setValueFromCoords(columnIndex, rowIndex, originalFormula, true);
          }
        });
      });

      this.waitingForCrossTableFormulas = false;
      worksheet.parent.config.editable  = !this.locked;
    },
    handleOnChange(worksheet, _cell, colIndex, rowIndex, newValue, oldValue) {
      // When formulas render, an onchange event is fired, but both values are the same.
      // We want to ignore this.
      if (newValue[0] === '=' && oldValue === newValue && this.findCalculatedValue(colIndex, rowIndex) === worksheet.getValueFromCoords(colIndex, rowIndex, true)) return;

      this.debouncedUpdate();
    },
    async loadFile(event) {
      jspreadsheet.parser({
        file: event.target.files[0],
        locale: "en-GB",
        onload: async (config) => {
          if ( await this.$refs.importXlsxModal.show() ) {
            this.importSpreadsheet(config.worksheets[0], config.style);
          }
          this.$refs.fileInput.value = '';
        },
        onerror: (error) => {
          this.importError = true;
          this.$refs.fileInput.value = '';
        },
      });
    },
    importSpreadsheet(worksheet, styles) {
      const metadata = this.element.metadata;
      const columnsProperties = metadata.columns_properties;

      metadata.columns_size = worksheet.data[0].map((_, i) => {
        const width = parseInt(worksheet.columns[i]?.width || 100);
        if (columnsProperties) {
          (columnsProperties[i] ||= { properties: {} }).properties.width = width;
        }
        return width;
      });

      metadata.rows_size = Object.values(worksheet.rows).map(row => row?.height || 27);

      if (worksheet.style) {
        metadata.cells_style = Object.fromEntries(
          Object.entries(worksheet.style).map(([cell, style]) => [cell, styles[style]])
        );
      }

      metadata.cells_merge = worksheet.mergeCells;
      this.tableData = worksheet.data;

      this.$nextTick(() => {
        this.debouncedUpdate();
        this.tableKey += 1;
      });
    },
    handleFormula(_, expression){
      // We need to support ; and , for separation of formula parameters
      return expression.replace(/;/g, ',');
    },
    onloadTable() {
      if (this.$refs.spreadsheet.current) {
        this.$nextTick(() => {
          // this part applies additional cell and column properties, such as column names and locked cells:
          const worksheet = this.$refs.spreadsheet.current[0];
          const cellProperties = this.element.metadata.cells_properties;
          const columnProperties = this.element.metadata.columns_properties;

          worksheet.parent.config.editable = true;

          try {
            if (cellProperties) {
              cellProperties.forEach((cell) => {
                worksheet.setProperty(cell.x, cell.y, cell.properties);

                if (cell.properties.type == 'numeric') {
                  // Force re-render so type/mask/decimalPlaces take effect on existing values
                  worksheet.setProperty(cell.x, cell.y, {});
                  setTimeout(() => {
                    worksheet.parent.config.editable = true; // allow edits during this operation
                    worksheet.setProperty(cell.x, cell.y, cell.properties);
                    worksheet.parent.config.editable  = !this.locked;
                  }, 0);
                }
              });
            }

            if (columnProperties && !this.isWellPlate) {
              columnProperties.forEach((column) => {
                worksheet.setProperty(column.x, column.properties);
              });
            }
          } catch { // table might not have been fully loaded in some cases, so try to apply again after a bit
            setTimeout(() => {
              this.onloadTable();
            }, 100);
          }

          worksheet.parent.config.editable  = !this.locked;
          // end

          this.tableLoaded = true;
          this.renderSmartAnnotations();
          this.updateViewport();

          if (window.loadingTablesCount) {
            setTimeout(() => {
              window.loadingTablesCount -= 1;
              if (window.loadingTablesCount === 0) {
                window.dispatchEvent(new CustomEvent("jspreadsheet-tables-loaded"));
              }
            }, 2000);
          }
        });
      } else {
        setTimeout(() => {
          this.onloadTable();
        }, 100);
      }
    },
    saveSmartAnnotationToCell(value) {
      const worksheet = this.$refs.spreadsheet.current[0];
      worksheet.updateCell(this.selectedCell.x, this.selectedCell.y, value, true);

      this.openSmartAnnotationModal = false;
    },
    enableNameEdit() {
      this.editingName = true;
    },
    disableNameEdit() {
      this.editingName = false;
    },
    updateName(name) {
      this.element.name = name;
      this.$emit('update', this.element, false);
    },
    openNameModal() {
      this.tableObject.deselectCell();
      this.nameModalOpen = true;
    },
    updateEmptyName(name) {
      this.disableNameEdit();

      // force reload header to properly reset name inline edit
      this.reloadHeader += 1;

      this.element.name = name;
      this.$emit('update', this.element, false, () => {
        this.nameModalOpen = false;
        this.enableTableEdit();
      });
    },
    updateTable() {
      if (!this.$refs.spreadsheet?.current?.[0] || !this.tableLoaded) return;

      const spreadsheet = this.$refs.spreadsheet.current[0];
      const newTableData = spreadsheet.getData();
      const metadata = {
        cells_style: spreadsheet.getStyle(),
        cells_merge: spreadsheet.getMerge(),
        columns_size: spreadsheet.getWidth(),
        rows_size: spreadsheet.getHeight(),
        cells_properties: [],
        cells: [],
        sheet_name: spreadsheet.getWorksheetName(0)
      };

      // Add column properties if not a well plate
      if (!this.isWellPlate) {
        metadata.columns_properties = newTableData[0].map((_, columnIndex) => ({
          x: columnIndex,
          properties: spreadsheet.getProperty(columnIndex)
        }));
      }

      const computedCells = [];
      newTableData.forEach((row, rowIndex) => {
        row.forEach((cell, columnIndex) => {
          // Add cell properties
          metadata.cells_properties.push({
            x: columnIndex,
            y: rowIndex,
            properties: spreadsheet.getProperty(columnIndex, rowIndex)
          });

          // Process formula cells
          const tableCellProperty = spreadsheet.getProperty(columnIndex, rowIndex);
          if ((typeof cell === 'string' && cell.startsWith('=')) || tableCellProperty.type === 'numeric') {
            const calculated = spreadsheet.getValueFromCoords(columnIndex, rowIndex, true);
            const formulaCell = {
              col: columnIndex,
              row: rowIndex,
              calculated
            };

            computedCells.push(formulaCell);
            metadata.cells.push(formulaCell);
          }
        });
      });

      this.element.contents = JSON.stringify({ data: newTableData });
      this.element.metadata = { ...metadata };
      this.computedCells = computedCells;
      this.updateViewport();
    },
    editingStarted() {
      this.editingTable = true;

      // rename wellplate columns
      if (this.isWellPlate) this.updateColumnHeaders(key => `${key + 1}(${this.integerToCharacter(key + 1)})`);
    },
    editingEnded() {
      // restore wellplate column names
      if (this.isWellPlate) this.updateColumnHeaders(key => key + 1);

      this.renderSmartAnnotations();
    },
    updateColumnHeaders(formatFunction) {
      const columnCount = this.tableData[0].length;
      for (let key = 0; key < columnCount; key++) {
        const header = this.$refs.spreadsheetContainer.querySelector(`.jss_header[data-x="${key}"]`);
        if (header) header.innerHTML = formatFunction(key);
      }
    },
    integerToCharacter(c) {
      let result = '';
      while (c > 0) {
        c -= 1;
        result = String.fromCharCode((c % 26) + 65) + result;
        c = Math.floor(c / 26);
      }
      return result;
    },
    changeColumnName(name) {
      this.openRenameColumnModal = false;
      const property = this.$refs.spreadsheet.current[0].getProperty(this.columnToRename);
      property.title = name;
      this.$refs.spreadsheet.current[0].setProperty(this.columnToRename, property);
      this.debouncedUpdate();
    },
    changeWorksheetName(name) {
      this.openRenameWorksheetModal = false;
      this.$refs.spreadsheet.current[0].renameWorksheet(0, name);
      this.debouncedUpdate();
    },
    updateViewport() {
      const tableElement = this.$refs.spreadsheet.el.querySelector('table.jss');
      let width = Math.min(this.$refs.tableContainer.offsetWidth, tableElement.offsetWidth) + 10;
      if (width < 320) width = 320;
      this.$refs.spreadsheet.current[0].setViewport(
        width,
        Math.min(500, tableElement.offsetHeight + 10)
      );
    },
    renderSmartAnnotations() {
      if (this.$refs.spreadsheet) {
        this.$nextTick(() => {
          this.$refs.spreadsheet.el.classList.remove('sa-initialized');  // force re-render of smart annotations
          window.renderElementSmartAnnotations(this.$refs.spreadsheet.el, 'td', [window, this.$refs.spreadsheet.el.querySelector('.jss_content')]);
        });
      }
    },
    findCalculatedValue(col, row){
      if (!this.computedCells || !this.computedCells.find || this.computedCells.length === 0) return;

      const cell = this.computedCells.find(
        (cell) => cell.col === col && cell.row === row
      );

      return cell?.calculated;
    },
    closeArchiveModal() {
      this.confirmingArchive = false;
    }
  }
};
</script>
