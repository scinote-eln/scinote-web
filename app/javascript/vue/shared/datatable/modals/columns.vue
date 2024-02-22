<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t('experiments.table.column_display_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="max-h-90 overflow-y-auto">
            <Draggable
              v-model="columnsList"
              :forceFallback="true"
              :handle="'.element-grip'"
              item-key="field"
              @end="endReorder"
            >
              <template #item="{element}">
                <div
                  class="flex items-center gap-4 py-2.5 px-3 group/column"
                  :class="{
                    'hover:bg-sn-super-light-grey': element.field !== 'pinnedSeparator',
                    '!py-2.5': element.field === 'pinnedSeparator',
                    'text-sn-grey': (element.field !== 'pinnedSeparator' && !columnVisbile(element))
                  }"
                >
                  <div v-if="element.field == 'pinnedSeparator'" class="h-[1px] w-full bg-sn-sleepy-grey"></div>
                  <template v-else>
                    <div class="opacity-0 group-hover/column:!opacity-100 element-grip cursor-pointer">
                      <i class="sn-icon sn-icon-drag"></i>
                    </div>
                    <div v-if="element.field === 'name'" class="w-6 h-6"></div>
                    <template v-else>
                      <i v-if="columnVisbile(element)" @click="toggleColumn(element, true)"
                        class="sn-icon sn-icon-visibility-show cursor-pointer"></i>
                      <i v-else @click="toggleColumn(element, false)"
                        class="sn-icon sn-icon-visibility-hide cursor-pointer"></i>
                    </template>
                    <div class="truncate">{{ element.headerName }}</div>
                    <div class="ml-auto cursor-pointer">
                      <i v-if="columnPinned(element)" @click="unPinColumn(element)" class="sn-icon sn-icon-pinned"></i>
                      <i v-else @click="pinColumn(element)" class="sn-icon sn-icon-pin"></i>
                    </div>
                  </template>
                </div>
              </template>
            </Draggable>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary mr-auto" @click="resetToDefault">
            {{ i18n.t('experiments.table.column_display_modal.reset_to_default') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../../modal_mixin';
import Draggable from 'vuedraggable';

export default {
  name: 'NewModal',
  props: {
    columnDefs: { type: Array, required: true },
    tableState: { type: Object }
  },
  components: {
    Draggable
  },
  data() {
    return {
      currentTableState: {},
      columnsList: []
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
    }
  },
  mixins: [modalMixin],
  methods: {
    resetToDefault() {
      this.$emit('resetToDefault');
      this.close();
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
    endReorder(event) {
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
