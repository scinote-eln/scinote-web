<template>
  <div>
    <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-manageColumnsModal-close">
        <i class="sn-icon sn-icon-close"></i>
      </button>
      <h4 class="modal-title truncate !block" data-e2e="e2e-TX-manageColumnsModal-title">
        {{ i18n.t('experiments.table.column_display_modal.title') }}
      </h4>
    </div>
    <div class="modal-body">
      <div v-if="canEnforceTableState" class="flex items-start gap-4 p-4 mb-4 rounded bg-sn-super-light-grey" data-e2e="e2e-CT-manageColumnsModal-enforceTableState">
        <div class="grow">
          <div class="font-bold mb-1">{{ i18n.t('repositories.enforce_table_state.title') }}</div>
          <div>{{ i18n.t('repositories.enforce_table_state.description') }}</div>
        </div>
        <span class="sci-toggle-checkbox-container shrink-0">
          <input type="checkbox"
                 class="sci-toggle-checkbox"
                 data-e2e="e2e-TG-manageColumnsModal-enforceTableState"
                 :checked="enforceTableState"
                 :disabled="savingEnforceTableState"
                 @change="$emit('toggleEnforceTableState', $event.target.checked)" />
          <span class="sci-toggle-checkbox-label"></span>
        </span>
      </div>
      <div class="max-h-90 overflow-y-auto">
        <Draggable
          v-model="columnsList"
          :forceAutoScrollFallback="true"
          :handle="'.element-grip'"
          :disabled="!canOverrideState('columnsOrder')"
          item-key="field"
          @start="startReorder"
          @end="endReorder"
        >
          <template #item="{element}">
            <div
              class="flex items-center gap-4 py-2.5 px-3 group"
              :class="{
                'select-none': reordering,
                'hover:bg-sn-super-light-grey': element.field !== 'pinnedSeparator',
                '!py-2.5': element.field === 'pinnedSeparator',
                'text-sn-grey': (element.field !== 'pinnedSeparator' && !columnVisbile(element))
              }"
            >
              <div v-if="element.field == 'pinnedSeparator'" class="h-[1px] w-full bg-sn-sleepy-grey"></div>
              <template v-else>
                <div v-if="canOverrideState('columnsOrder')" class="element-grip cursor-pointer" :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-drag'">
                  <i class="sn-icon sn-icon-drag"></i>
                </div>
                <div v-if="element.field === 'name' || !canOverrideState('columnsVisibility')" class="w-6 h-6"></div>
                <i v-else-if="isMandatory(element)"
                   class="sn-icon sn-icon-visibility-show text-sn-grey cursor-not-allowed"
                   :data-e2e="'e2e-IC-manageColumnsModal-'+element.field+'-mandatoryVisible'"></i>
                <template v-else>
                  <i v-if="columnVisbile(element)" @click="toggleColumn(element, true)"
                    class="sn-icon sn-icon-visibility-show cursor-pointer" :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-hide'"></i>
                  <i v-else @click="toggleColumn(element, false)"
                    class="sn-icon sn-icon-visibility-hide cursor-pointer" :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-show'"></i>
                </template>
                <div class="truncate grow" :data-e2e="'e2e-TX-manageColumnsModal-'+element.field+'-columnName'">{{ element.headerName }}</div>
                <div v-if="columnType(element)" class="text-sn-grey shrink-0" :data-e2e="'e2e-TX-manageColumnsModal-'+element.field+'-columnType'">
                  {{ columnType(element) }}
                </div>
                <template v-if="canManageColumns && isManageable(element)">
                  <i class="sn-icon sn-icon-edit cursor-pointer tw-hidden group-hover:block"
                     :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-edit'"
                     @click="$emit('edit', element)"></i>
                  <i class="sn-icon sn-icon-delete cursor-pointer tw-hidden group-hover:block"
                     :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-delete'"
                     @click="$emit('delete', element)"></i>
                </template>
                <div v-if="canManageColumns && canBeMandatory(element)"
                     class="cursor-pointer shrink-0"
                     :class="{
                       'tw-hidden group-hover:block': !isMandatory(element),
                       'pointer-events-none opacity-50': togglingMandatory === element.field
                     }"
                     :title="isMandatory(element) ? i18n.t('repositories.mandatory_column.unmark') : i18n.t('repositories.mandatory_column.mark')"
                     :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-mandatory'"
                     @click="$emit('toggleMandatory', element)">
                  <i class="sn-icon"
                     :class="isMandatory(element) ? 'sn-icon-required-columns-on' : 'sn-icon-required-columns-off'"></i>
                </div>
                <div v-if="canOverrideState('columnsPinning')" class="ml-auto cursor-pointer" :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-pin'">
                  <i v-if="columnPinned(element)" @click="unPinColumn(element)" class="sn-icon sn-icon-pinned"></i>
                  <i v-else @click="pinColumn(element)" class="sn-icon sn-icon-pin"></i>
                </div>
              </template>
            </div>
          </template>
        </Draggable>
      </div>
    </div>
    <div class="modal-footer flex items-center">
      <button type="button" class="btn btn-secondary mr-auto" @click="$emit('resetToDefault')" data-e2e="e2e-BT-manageColumnsModal-resetToDefault">
        {{ i18n.t('experiments.table.column_display_modal.reset_to_default') }}
      </button>
      <button v-if="canManageColumns" type="button" class="btn btn-primary" @click="$emit('add')" data-e2e="e2e-BT-manageColumnsModal-addColumn">
        <i class="sn-icon sn-icon-new-task"></i>&nbsp;{{ i18n.t('libraries.manange_modal_column_index.add_column') }}
      </button>
    </div>
  </div>
</template>

<script>
import Draggable from 'vuedraggable';
import { typeLabel } from './column_types.js';
import { canOverride, FULL_TABLE_STATE_PERMISSIONS } from '../../../shared/datatable/table_state.js';

export default {
  name: 'ColumnsList',
  props: {
    columnDefs: { type: Array, required: true },
    tableState: { type: Object },
    canManageColumns: { type: Boolean, default: false },
    canEnforceTableState: { type: Boolean, default: false },
    enforceTableState: { type: Boolean, default: false },
    savingEnforceTableState: { type: Boolean, default: false },
    togglingMandatory: { type: String, default: null },
    mandatoryColumns: { type: Object, default: () => ({}) },
    tableStatePermissions: { type: Object, default: () => ({ ...FULL_TABLE_STATE_PERMISSIONS }) }
  },
  components: {
    Draggable
  },
  data() {
    return {
      currentTableState: {},
      columnsList: [],
      reordering: false
    };
  },
  created() {
    this.syncColumns();
  },
  watch: {
    tableState: {
      handler() {
        this.syncColumns();
      },
      deep: true
    },
    columnDefs: {
      handler() {
        this.syncColumns();
      }
    }
  },
  methods: {
    canOverrideState(attribute) {
      return canOverride(this.tableStatePermissions, attribute);
    },
    isManageable(column) {
      return !!column.cellRendererParams?.columnId;
    },
    canBeMandatory(column) {
      return this.isManageable(column) && column.cellRendererParams.columnDataType !== 'RepositoryStockValue';
    },
    isMandatory(column) {
      return !!(this.mandatoryColumns[column.field] ?? column.cellRendererParams?.mandatory);
    },
    columnType(column) {
      const dataType = column.cellRendererParams?.columnDataType;
      return dataType ? typeLabel(this.i18n, dataType) : null;
    },
    columnVisbile(column) {
      return !this.currentTableState.columnsState?.find((col) => col.colId === column.field).hide;
    },
    columnPinned(column) {
      return this.currentTableState.columnsState?.find((col) => col.colId === column.field).pinned;
    },
    toggleColumn(column, visible) {
      if (column.field === 'name') return;
      if (visible && this.isMandatory(column)) return;

      if (visible) {
        this.$emit('hideColumn', column);
      } else {
        this.$emit('showColumn', column);
      }
    },
    pinColumn(column) {
      this.$emit('pinColumn', column);
    },
    unPinColumn(column) {
      this.$emit('unPinColumn', column);
    },
    syncColumns() {
      this.currentTableState = this.tableState;
      this.currentTableState.columnsState.forEach((col, index) => {
        col.position = index;
      });

      let columns = this.currentTableState.columnsState
        .sort((a, b) => {
          if (a.pinned === b.pinned) {
            return a.position - b.position;
          }
          return a.pinned ? -1 : 1;
        });

      const pinnedAmount = columns.filter((col) => col.pinned).length;
      columns = columns
        .map((col) => this.columnDefs.find((c) => c.field === col.colId))
        .filter((col) => col);
      this.columnsList = [
        ...columns.slice(0, pinnedAmount - 1),
        { field: 'pinnedSeparator' },
        ...columns.slice(pinnedAmount - 1)
      ];
    },
    startReorder() {
      this.reordering = true;
    },
    endReorder(event) {
      this.reordering = false;
      this.$nextTick(() => {
        const { newIndex } = event;
        const columnName = this.columnsList[newIndex].field;
        const separatorIndex = this.columnsList.findIndex((col) => col.field === 'pinnedSeparator');
        const reordedColumns = this.columnsList.filter((col) => col.field !== 'pinnedSeparator');

        const columnsOrdered = reordedColumns.map((col) => col.field);
        this.$emit('reorderColumns', columnsOrdered);

        if (!this.canOverrideState('columnsPinning')) return;

        if (newIndex <= separatorIndex) {
          this.pinColumn(this.columnDefs.find((col) => col.field === columnName));
        } else {
          this.unPinColumn(this.columnDefs.find((col) => col.field === columnName));
        }
      });
    }
  }
};
</script>
