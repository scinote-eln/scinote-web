<template>
  <div class="h-full">
    <DataTable
      v-if="repositoryColumnsDef.length > 0"
      :columnDefs="repositoryColumnsDef"
      :tableId="'repository_table_' + repositoryId"
      :dataUrl="dataSource"
      :reloadingTable="reloadingTable"
      :toolbarActions="toolbarActions"
      :actionsUrl="toolbarActionsUrl"
      :filters="[]"
      :enableBarcodeSearch="true"
      :fetchColumnsOnReload="true"
      @tableReloaded="reloadingTable = false"
    ></DataTable>
  </div>
</template>
<script>
import DataTable from '../shared/datatable/table.vue';
import axios from '../../packs/custom_axios.js';
import ColumnsMixin from './columns_mixin.js';

import {
  repository_table_index_ag_path,
  repository_path
} from '../../routes.js';

export default {
  name: 'RepositoryTable',
  props: {
    repositoryId: Number
  },
  components: {
    DataTable
  },
  mixins: [ColumnsMixin],
  data: () => ({
    repositoryVersion: null,
  }),
  created() {
    this.loadRepository();
  },
  computed: {
    toolbarActions() {
      const left = [];
      const right = [];

      return {
        left: left,
        right: right
      };
    },
    dataSource() {
      return repository_table_index_ag_path(this.repositoryId);
    },
    repositoryUrl() {
      return repository_path(this.repositoryId);
    },
    toolbarActionsUrl() {
      return '';
    },
  },
  methods: {
    loadRepository() {
      axios.get(this.repositoryUrl)
        .then((response) => {
          this.repositoryVersion = response.data.data;
          this.loadRepositoryColumns();
        });
    }
  }
};
</script>
