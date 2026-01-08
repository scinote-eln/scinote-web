import axios from '../../packs/custom_axios.js';
import cellRenderer from './renderers/cell_renderer.vue';
import nameRenderer from './renderers/name_renderer.vue';
import consumeRenderer from './renderers/consume_renderer.vue';
import {
  index_new_repository_repository_columns_path
} from '../../routes.js';

export default {
  components: {
    cellRenderer,
    nameRenderer,
    consumeRenderer
  },
  data() {
    return {
      repositoryColumnsDef: []
    };
  },
  computed: {
    defaultRepositoryColumnsDef() {
      let columns = [{
        field: 'name',
        headerName: this.i18n.t('repositories.table.row_name'),
        sortable: true,
        notSelectable: true,
        cellRenderer: 'nameRenderer'
      },
      {
        field: 'code',
        headerName: this.i18n.t('repositories.table.id'),
        sortable: true
      },
      {
        field: 'assigned',
        headerName: this.i18n.t('repositories.table.assigned'),
        sortable: true
      },
      {
        field: 'connections',
        headerName: this.i18n.t('repositories.table.relationships')
      },
      {
        field: 'created_at',
        headerName: this.i18n.t('repositories.table.added_on'),
        sortable: true
      },
      {
        field: 'created_by',
        headerName: this.i18n.t('repositories.table.added_by'),
        sortable: true
      }];
      return columns;
    }
  },
  mounted() {
    if (this.repository) {
      this.loadRepositoryColumns();
    }
  },
  methods: {
    loadRepositoryColumns() {
      axios.get(index_new_repository_repository_columns_path(this.repository.id))
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
              notSelectable: true,
              columnId: column.id,
              columnItems: column.attributes.column_items,
              columnDataType: column.attributes.data_type
            });

            if (field == 'stock' && this.myModuleId) {
              columns.push({
                field: 'consumed_stock',
                headerName: this.i18n.t('repositories.table.row_consumption'),
                sortable: true,
                notSelectable: true,
                cellRenderer: 'consumeRenderer'
              });
            }
          });
          this.repositoryColumnsDef = columns;
        })
    }
  }
};
