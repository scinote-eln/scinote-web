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
      <div class="max-h-90 overflow-y-auto">
        <Draggable
          v-model="columnsList"
          :forceAutoScrollFallback="true"
          :handle="'.element-grip'"
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
                <div class="opacity-0 group-hover:!opacity-100 element-grip cursor-pointer" :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-drag'">
                  <i class="sn-icon sn-icon-drag"></i>
                </div>
                <div v-if="element.field === 'name'" class="w-6 h-6"></div>
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
                <div class="ml-auto cursor-pointer" :data-e2e="'e2e-BT-manageColumnsModal-'+element.field+'-pin'">
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

export default {
  name: 'ColumnsList',
  props: {
    columnDefs: { type: Array, required: true },
    tableState: { type: Object },
    canManageColumns: { type: Boolean, default: false }
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
    isManageable(column) {
      return !!column.cellRendererParams?.columnId;
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
