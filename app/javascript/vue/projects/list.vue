<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="ProjectsList"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               :withRowMenu="true"
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
    }
  },
  methods: {
    nameRenderer(params) {
      let showUrl = params.data.urls.show;
      return `<a href="${showUrl}" class="flex items-center gap-1">
                ${params.data.folder ? 'sn-icon mini sn-icon-mini-folder-left' : ''}
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
