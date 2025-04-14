import { createApp } from 'vue/dist/vue.esm-bundler.js';
import DataTable from '../../../vue/shared/datatable/table.vue';
import DescriptionRenderer from '../../../vue/shared/datatable/renderers/description.vue';
import DateRenderer from '../../../vue/shared/datatable/renderers/date.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      dataUrl: '/design_elements/test_table'
    };
  },
  computed: {
    columnDefs() {
      const columns = [
        {
          field: 'name',
          flex: 1,
          headerName: 'Name',
          sortable: true
        },
        {
          field: 'description',
          flex: 1,
          headerName: 'Description',
          sortable: true,
          cellRenderer: DescriptionRenderer
        },
        {
          field: 'date',
          flex: 1,
          headerName: 'Date',
          sortable: true,
          cellRenderer: DateRenderer,
          cellRendererParams: {
            placeholder: 'Add date',
            field: 'date',
            mode: 'datetime',
            emptyPlaceholder: 'No date',
            emitAction: 'updateDate'
          }
        }
      ];

      return columns;
    },
    viewRenders() {
      return [];
    },
    toolbarActions() {
      return {
        left: [],
        right: []
      };
    },
    filters() {
      const filters = [];

      return filters;
    }
  }
});
app.component('DataTable', DataTable);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#table');
