<template>
  <div>
    <p>{{ i18n.t('my_modules.repository.assign_modal.assignment_disclaimer') }}</p>
    <div class="relative">
      <div class="absolute left-0 z-50 w-64 top-4">
        <SelectDropdown
          :optionsUrl="repositoriesUrl"
          placeholder="Select inventory"
          :searchable="true"
          :value="selectedRepositoryId"
          :disabled="disabledRepositoryDropdown"
          @change="changeRepository"
          :e2eValue="`e2e-DD-${dataE2e}-selectInventory`"
        ></SelectDropdown>
      </div>
      <div v-if="repositoryVersion" :key="repositoryVersion.id" style="height: 540px">
        <DataTable
          v-if="repositoryColumnsDef.length > 0"
          :columnDefs="repositoryColumnsDef"
          :tableId="`my_module_unassigned_repository_rows_my_module_${myModuleId}_repository_${repositoryVersion.id}`"
          :dataUrl="dataSource"
          :reloadingTable="reloadingTable"
          :toolbarActions="toolbarActions"
          :actionsUrl="toolbarActionsUrl"
          :hideColumnsManagment="true"
          :filters="[]"
          :tableOnly="true"
          :skipSaveTableState="true"
          :enableBarcodeSearch="true"
          :fetchColumnsOnReload="true"
          @tableReloaded="reloadingTable = false"
          @assign="assignItems"
          @assign_downstream="assignItemsDownstream"
        ></DataTable>
      </div>
      <div v-else class="flex items-center justify-center" style="height: 540px">
        <span class="text-gray-500">
          {{ i18n.t('my_modules.repository.assign_modal.no_repository_selected') }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../../shared/select_dropdown.vue';
import axios from '../../../../packs/custom_axios.js';
import DataTable from '../../../shared/datatable/table.vue';
import ColumnsMixin from '../../../repository/columns_mixin.js';
import {
  list_repositories_path,
  unassigned_rows_my_module_repository_path,
  unassigned_actions_toolbar_my_module_repository_path,
} from '../../../../routes.js';

export default {
  name: 'AssignItemsTable',
  props: {
    myModuleId: String,
    selectedRepositoryId: {
      type: Number,
      required: true
    },
    dataE2e: {
      type: String,
      default: ''
    }
  },
  mixins: [ColumnsMixin],
  components: {
    SelectDropdown,
    DataTable
  },
  created() {
    this.teamId = document.body.dataset.currentTeamId;
    if (this.selectedRepositoryId) {
      this.disabledRepositoryDropdown = true;
      this.repositoryVersion = {
        id: this.selectedRepositoryId,
        attributes: {}
      }

    }
  },
  watch: {
    repositoryVersion() {
      this.repositoryColumnsDef = [];
      this.loadRepositoryColumns();
    }
  },
  computed: {
    repositoriesUrl() {
      return list_repositories_path({ non_empty: true, active: true });
    },
    openSize() {
      return this.onlyRepository ? '540px' : '600px';
    },
    toolbarActions() {
      const left = [];
      const right = [];
      return {
        left: left,
        right: right
      };
    },
    dataSource() {
      if (!this.repositoryVersion) {
        return null;
      }

      return unassigned_rows_my_module_repository_path(this.myModuleId, this.repositoryVersion.id, {archived: false});
    },
    toolbarActionsUrl() {
      if (!this.repositoryVersion) {
        return null;
      }

      return unassigned_actions_toolbar_my_module_repository_path(this.myModuleId, this.repositoryVersion.id);
    },
  },
  data() {
    return {
      repositoryVersion: null,
      teamId: null,
      disabledRepositoryDropdown: false,
      reloadingTable: false
    };
  },
  methods: {
    changeRepository(repositoryId) {
      this.repositoryVersion = {
        id: repositoryId,
        attributes: {}
      };
    },
    assignItems(event, rowIds) {
      this.$emit('assign', event, rowIds, this.repositoryVersion.id);
    },
    assignItemsDownstream(event, rowIds) {
      this.$emit('assign_downstream', event, rowIds, this.repositoryVersion.id);
    }
  }
};
</script>
