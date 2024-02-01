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
          <p class='modal-description'>
            {{ i18n.t("experiments.table.column_display_modal.description") }}
          </p>
          <div class="max-h-90 overflow-y-auto">
            <div
              v-for="column in columnDefs"
              :key="column.field"
              @click="toggleColumn(column, columnVisbile(column))"
              class="flex items-center gap-4 py-2.5 px-3"
              :class="{
                'cursor-pointer': column.field !== 'name',
                'hover:bg-sn-super-light-grey': column.field !== 'name'
              }"
            >
              <div v-if="column.field === 'name'" class="w-6 h-6"></div>
              <template v-else>
                <i v-if="columnVisbile(column)"
                  class="sn-icon sn-icon-visibility-show"></i>
                <i v-else
                  class="sn-icon sn-icon-visibility-hide"></i>
                </template>
              <div class="truncate">{{ column.headerName }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../../modal_mixin';

export default {
  name: 'NewModal',
  props: {
    columnDefs: { type: Array, required: true },
    tableState: { type: Object }
  },
  data() {
    return {
      currentTableState: {}
    };
  },
  created() {
    this.currentTableState = this.tableState;
  },
  mixins: [modalMixin],
  methods: {
    columnVisbile(column) {
      return !this.currentTableState.columnsState?.find((col) => col.colId === column.field)?.hide;
    },
    toggleColumn(column, visible) {
      if (column.field === 'name') return;

      this.currentTableState.columnsState.find((col) => col.colId === column.field).hide = visible;
      if (visible) {
        this.$emit('hideColumn', column);
      } else {
        this.$emit('showColumn', column);
      }
    }
  }
};
</script>
