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
        cellRenderer: 'nameRenderer',
        cellRendererParams: {
          legacyId: -4
        }
      },
      {
        field: 'code',
        headerName: this.i18n.t('repositories.table.id'),
        sortable: true,
        cellRendererParams: {
          legacyId: -3
        }
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
        hide: this.columnHidden,
        cellRendererParams: {
          legacyId: -11
        }
      },
      {
        field: 'created_at',
        headerName: this.i18n.t('repositories.table.added_on'),
        sortable: true,
        hide: this.columnHidden,
        cellRendererParams: {
          legacyId: -6
        },
      },
      {
        field: 'created_by',
        headerName: this.i18n.t('repositories.table.added_by'),
        sortable: true,
        hide: this.columnHidden,
        cellRendererParams: {
          legacyId: -5
        },
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
              hide: !(field == 'stock') && this.columnHidden,
              cellRendererParams: {
                repositoryId: this.repository.id,
                columnId: column.id,
                columnDataType: column.attributes.data_type,
                legacyId: parseInt(column.id, 10)
              },
              notSelectable: true
            });

            if (field == 'stock' && this.myModuleId) {
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
    }
  }
};
