<template>
  <div>
    <p>{{ i18n.t('my_modules.repository.assign_modal.assignment_disclaimer') }}</p>
    <div class="relative">
      <div class="absolute left-0 right-[272px] z-50 top-4">
        <div v-if="!selectedRepositoryId" class="w-64">
          <SelectDropdown
            v-if="!selectedRepositoryId"
            :optionsUrl="repositoriesUrl"
            placeholder="Select inventory"
            :searchable="true"
            :value="selectedRepositoryId"
            :disabled="disabledRepositoryDropdown"
            :class="w-64"
            @change="changeRepository"
            :e2eValue="`e2e-DD-${dataE2e}-selectInventory`"
          ></SelectDropdown>
        </div>
          <h4 v-else class="!leading-10 truncate !block" :title="selectedRepositoryName">
          {{ selectedRepositoryName }}
        </h4>
      </div>
      <div v-if="repositoryVersion" :key="repositoryVersion.id" style="height: 540px">
        <DataTable
          ref="repositoryTable"
          v-if="repositoryColumnsDef.length > 0"
          :columnDefs="repositoryColumnsDef"
          :tableId="`my_module_unassigned_repository_rows_my_module_${myModuleId}_repository_${repositoryVersion.id}`"
          :dataUrl="dataSource"
          :reloadingTable="reloadingTable"
          :toolbarActions="toolbarActions"
          :actionsUrl="toolbarActionsUrl"
          :hideColumnsManagment="true"
          loadMethod="post"
          :postParams="{
            advanced_search: {
              filter_elements: activeFilter
            }
          }"
          @showTextCell="showTextCellModal"
          :filters="[]"
          :tableOnly="true"
          :skipSaveTableState="true"
          :enableBarcodeSearch="true"
          :fetchColumnsOnReload="true"
          @tableReloaded="reloadingTable = false"
          @applyFilters="applyFilters"
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
    <teleport to="body">
      <TextCellModal
        v-if="textCellModalObject"
        :row="textCellModalObject.row"
        :colDef="textCellModalObject.colDef"
        @close="textCellModalObject = null"/>
    </teleport>
  </div>
</template>

<script>
import axios from '../../../../packs/custom_axios.js';
import SelectDropdown from '../../../shared/select_dropdown.vue';
import DataTable from '../../../shared/datatable/table.vue';
import ColumnsMixin from '../../../repository/columns_mixin.js';
import TextCellModal from '../../../repository/modals/text_cell.vue';
import RepositoryFilters from '../../../repository/filters.vue';
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
    dataE2e: { type: String, required: true }
  },
  mixins: [ColumnsMixin],
  components: {
    SelectDropdown,
    DataTable,
    TextCellModal,
    RepositoryFilters
  },
  created() {
    this.teamId = document.body.dataset.currentTeamId;
    if (this.selectedRepositoryId) {
      this.repositoryVersion = {
        id: this.selectedRepositoryId,
        attributes: {}
      }
      axios.get(this.repositoriesUrl)
           .then(response => {
             this.selectedRepositoryName = response.data.data.find(repo => repo[0] == this.selectedRepositoryId)[1];
           });
    }
  },
  mounted() {
    window.repositoryAssignTable = this;
  },
  unmounted() {
    window.repositoryAssignTable = null;
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

      right.push({
        name: 'filters',
        type: 'component',
        params: {
          componentRenderer: RepositoryFilters,
          repositoryId: parseInt(this.selectedRepositoryId, 10)
        }
      });

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
      reloadingTable: false,
      selectedRepositoryName: '',
      textCellModalObject: null,
      activeFilter: []
    };
  },
  methods: {
    updateRowData(row) {
      this.$refs.repositoryTable.updateRowData(row);
    },
    changeRepository(repositoryId) {
      this.repositoryVersion = {
        id: repositoryId,
        attributes: {}
      };
    },
    showTextCellModal(_e, rows, colDef) {
      this.textCellModalObject = {
        row: rows[0],
        colDef
      }
    },
    applyFilters(filters) {
      this.activeFilter = filters.data
      this.reloadingTable = true
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
