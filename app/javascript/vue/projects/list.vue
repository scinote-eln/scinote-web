<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="ProjectsList"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               :withRowMenu="true"
               :activePageUrl="activePageUrl"
               :archivedPageUrl="archivedPageUrl"
               :currentViewMode="currentViewMode"
               :filters="filters"
               @tableReloaded="reloadingTable = false"
      />
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue'
import UsersRenderer from './renderers/users.vue'

export default {
  name: 'ProjectsList',
  components: {
    DataTable,
    UsersRenderer,
  },
  props: {
    dataSource: {
      type: String,
      required: true
    },
    actionsUrl: {
      type: String,
      required: true
    },
    createUrl: {
      type: String,
    },
    createFolderUrl: {
      type: String,
    },
    activePageUrl: {
      type: String,
    },
    archivedPageUrl: {
      type: String,
    },
    currentViewMode: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      reloadingTable: false,
      columnDefs: [
                    { field: "name", flex: 1, headerName: this.i18n.t('projects.index.card.name'), sortable: true, cellRenderer: this.nameRenderer },
                    { field: "code", headerName: this.i18n.t('projects.index.card.id'), sortable: true },
                    { field: "created_at", headerName: this.i18n.t('projects.index.card.start_date'), sortable: true },
                    { field: "hidden", headerName: this.i18n.t('projects.index.card.visibility'), cellRenderer: this.visibiltyRenderer, sortable: false },
                    { field: "users", headerName: this.i18n.t('projects.index.card.users'), cellRenderer: 'UsersRenderer', sortable: false, minWidth: 210 }
                  ]
    }
  },
  computed: {
    toolbarActions() {
      let left = []
      if (this.createUrl) {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('projects.index.new'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
        })
      }
      if (this.createFolderUrl) {
        left.push({
          name: 'create_folder',
          icon: 'sn-icon sn-icon-folder',
          label: this.i18n.t('projects.index.new_folder'),
          type: 'emit',
          path: this.createFolderUrl,
          buttonStyle: 'btn btn-light',
        })
      }
      return {
        left: left,
        right: []
      }
    },
    filters() {
      let filters = [{
                      key: 'query',
                      type: 'Text'
                    },
                    {
                      key: 'created_at',
                      type: 'DateRange',
                      label: this.i18n.t("filters_modal.created_on.label"),
                    }]

      if (this.currentViewMode === 'archived') {
        filters.push({
          key: 'archived_at',
          type: 'DateRange',
          label: this.i18n.t("filters_modal.archived_on.label"),
        })
      }

      filters.push({
        key: 'folder_search',
        type: 'Checkbox',
        label: this.i18n.t("projects.index.filters_modal.folders.label"),
      })

      return filters
    }
  },
  methods: {
    nameRenderer(params) {
      let showUrl = params.data.urls.show;
      return `<a href="${showUrl}" class="flex items-center gap-1">
                ${params.data.folder ? '<i class="sn-icon mini sn-icon-mini-folder-left"></i>' : ''}
                ${params.data.name}
              </a>`
    },
    visibiltyRenderer(params) {
      if (params.data.type !== 'projects') return ''

      return params.data.hidden ? this.i18n.t('projects.index.hidden') : this.i18n.t('projects.index.visible');
    },
  }
}

</script>
