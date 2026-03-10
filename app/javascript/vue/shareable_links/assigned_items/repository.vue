<template>
  <div ref="container"
       class="p-4 bg-white rounded transition-all overflow-hidden mb-4"
       :style="{height: (sectionOpened ? '600px' : '60px')}">
    <div class="flex items-center h-6 gap-4 assigned-repository-title mb-1">
      <div
        @click="toggleContainer"
        class="flex items-center gap-4 grow overflow-hidden cursor-pointer"
        :data-e2e="`e2e-BT-task-assignedItems-inventory${ repository.id }-toggle`"
      >
        <i ref="openHandler" class="sn-icon sn-icon-right cursor-pointer"></i>
        <h3 class="my-0 flex items-center gap-4 overflow-hidden">
          <span :title="repository.name" class="assigned-repository-title truncate">{{ repository.name }}</span>
          <span class="text-sn-grey-500 font-normal text-base shrink-0">
            [{{ repository.assigned_rows_count }}]
          </span>
          <span class="bg-sn-light-grey  font-normal  px-1.5 py-1 rounded-full shrink-0 text-xs">
            <template v-if="repository.is_snapshot">
              {{  i18n.t('my_modules.repository.snapshots.simple_view.snapshot_tag') }}
            </template>
            <template v-else>
              {{  i18n.t('my_modules.repository.snapshots.simple_view.live_tag') }}
            </template>
          </span>

        </h3>
      </div>
    </div>
    <div style="height: 540px">
      <DataTable
        v-if="repositoryColumnsDef.length > 0"
        :columnDefs="repositoryColumnsDef"
        :dataUrl="dataSource"
      ></DataTable>
    </div>
  </div>
</template>
<script>
import DataTable from './table.vue';
import axios from '../../../packs/custom_axios.js';
import cellRenderer from '../../repository/renderers/cell_renderer.vue';
import consumeRenderer from '../../repository/renderers/consume_renderer.vue';

import {
  shared_protocol_items_path,
  shared_protocol_repositry_columns_path
} from '../../../routes.js';

export default {
  name: 'AssignedRepository',
  props: {
    repository: Object,
    myModuleUuid: String
  },
  components: {
    DataTable,
    cellRenderer,
    consumeRenderer
  },
  data: () => ({
    sectionOpened: false,
    reloadingTable: false,
    repositoryColumnsDef: []
  }),
  computed: {
    toolbarActions() {
     return {};
    },
    dataSource() {
      return shared_protocol_items_path(this.myModuleUuid, this.repository.id);
    },
    defaultRepositoryColumnsDef() {
      let columns = [{
        field: 'name',
        headerName: this.i18n.t('repositories.table.row_name'),
        sortable: true,
        notSelectable: true
      },
      {
        field: 'code',
        headerName: this.i18n.t('repositories.table.id'),
        sortable: true
      },
      {
        field: 'assigned_tasks_count',
        headerName: this.i18n.t('repositories.table.assigned'),
        sortable: true,
        hide: this.columnHidden
      },
      {
        field: 'connections_count',
        headerName: this.i18n.t('repositories.table.relationships'),
        hide: this.columnHidden
      },
      {
        field: 'created_at',
        headerName: this.i18n.t('repositories.table.added_on'),
        sortable: true,
        hide: this.columnHidden
      },
      {
        field: 'created_by',
        headerName: this.i18n.t('repositories.table.added_by'),
        sortable: true,
        hide: this.columnHidden
      }];
      return columns;
    },
    columnHidden() {
      return !this.repository.is_snapshot;
    }
  },
  mounted() {
    if (this.repository) {
      this.loadRepositoryColumns();
    }
  },
  methods: {
    loadRepositoryColumns() {
      axios.get(shared_protocol_repositry_columns_path(this.myModuleUuid, this.repository.id))
        .then((response) => {
          let columns = this.defaultRepositoryColumnsDef;
          response.data.data.forEach((column) => {
            let field = `col_${column.id}`;
            if (column.attributes.data_type == 'RepositoryStockValue') {
              field = 'stock';
            }
            columns.push({
              field: field,
              headerName: column.attributes.name,
              sortable: true,
              cellRenderer: 'cellRenderer',
              hide: !(field == 'stock') && this.columnHidden,
              cellRendererParams: {
                repositoryId: this.repository.id,
                columnId: column.id,
                columnDataType: column.attributes.data_type,
                legacyId: parseInt(column.id, 10)
              },
              notSelectable: true
            });

            if (field == 'stock' && this.myModuleUuid) {
              columns.push({
                field: 'consumed_stock',
                headerName: this.i18n.t('repositories.table.row_consumption'),
                sortable: true,
                notSelectable: true,
                cellRenderer: 'consumeRenderer',
                cellRendererParams: {
                  repositoryId: this.repository.id,
                }
              });
            }
          });
          this.repositoryColumnsDef = columns;
        })
        .catch(() => {
          // For private repositories we can't load the columns
          this.repositoryColumnsDef = [...this.defaultRepositoryColumnsDef];
        });
    },
    recalculateContainerSize() {
      const { container, openHandler } = this.$refs;

      if (this.sectionOpened) {
        container.style.height = '600px';
        openHandler.classList.remove('sn-icon-right');
        openHandler.classList.add('sn-icon-down');
      } else {
        container.style.height = '60px';
        openHandler.classList.remove('sn-icon-down');
        openHandler.classList.add('sn-icon-right');
      }
    },
    toggleContainer() {
      this.sectionOpened = !this.sectionOpened;
      this.recalculateContainerSize();
    },
  }
};
</script>
