import { createApp } from 'vue/dist/vue.esm-bundler.js';
import DataTable from '../shared/datatable/table.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  computed: {
    columnDefs() {
      const columns = [{
        field: 'name',
        flex: 1,
        headerName: this.i18n.t('projects.index.card.name'),
        sortable: true,
        cellRenderer: 'NameRenderer'
      }]

      return columns;
    },
    viewRenders() {
      return [
        { type: 'table' },
        { type: 'cards' }
      ];
    },
    toolbarActions() {
      const left = [];
      if (this.createUrl && this.currentViewMode !== 'archived') {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('projects.index.new'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
        });
      }
      if (this.createFolderUrl) {
        left.push({
          name: 'create_folder',
          icon: 'sn-icon sn-icon-folder',
          label: this.i18n.t('projects.index.new_folder'),
          type: 'emit',
          path: this.createFolderUrl,
          buttonStyle: 'btn btn-light'
        });
      }
      return {
        left,
        right: []
      };
    },
    filters() {
      const filters = [
        {
          key: 'query',
          type: 'Text'
        },
        {
          key: 'created_at',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.created_on.label')
        }
      ];

      if (this.currentViewMode === 'archived') {
        filters.push({
          key: 'archived_at',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.archived_on.label')
        });
      }

      filters.push({
        key: 'members',
        type: 'Select',
        optionsUrl: this.usersFilterUrl,
        optionRenderer: this.usersFilterRenderer,
        labelRenderer: this.usersFilterRenderer,
        label: this.i18n.t('projects.index.filters_modal.members.label'),
        placeholder: this.i18n.t('projects.index.filters_modal.members.placeholder')
      });

      filters.push({
        key: 'folder_search',
        type: 'Checkbox',
        label: this.i18n.t('projects.index.filters_modal.folders.label')
      });

      return filters;
    }
  }
});
app.component('DataTable', DataTable);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#table');
