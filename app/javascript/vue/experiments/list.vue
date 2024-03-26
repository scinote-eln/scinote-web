<template>
  <DataTable
    :columnDefs="columnDefs"
    tableId="ExperimentList"
    :dataUrl="dataSource"
    :reloadingTable="reloadingTable"
    :toolbarActions="toolbarActions"
    :actionsUrl="actionsUrl"
    :activePageUrl="activePageUrl"
    :archivedPageUrl="archivedPageUrl"
    :currentViewMode="currentViewMode"
    :filters="filters"
    :viewRenders="viewRenders"
    :objectArchived="archived"
    :hiddenDataMessage="i18n.t('projects.show.empty_state.no_active_experiment_archived_project')"
    scrollMode="infinite"
    @tableReloaded="reloadingTable = false"
    @archive="archive"
    @restore="restore"
    @showDescription="showDescription"
    @duplicate="duplicate"
    @move="move"
    @edit="edit"
    @create="create"
    @access="access"
  >
    <template #card="data">
      <ExperimentCard :params="data.params" :dtComponent="data.dtComponent" ></ExperimentCard>
    </template>
  </DataTable>

  <DescriptionModal
    v-if="descriptionModalObject"
    :experiment="descriptionModalObject"
    @close="descriptionModalObject = null"/>
  <DuplicateModal
    v-if="duplicateModalObject"
    :experiment="duplicateModalObject"
    @close="duplicateModalObject = null"/>
  <MoveModal
    v-if="moveModalObject"
    :experiment="moveModalObject"
    @close="moveModalObject = null"
    @move="updateTable"/>
  <EditModal
    v-if="editModalObject"
    :experiment="editModalObject"
    @close="editModalObject = null"
    @update="updateTable"/>
  <NewModal
    v-if="newModalOpen"
    :createUrl="createUrl"
    @close="newModalOpen = false"
    @create="updateTable"/>
  <AccessModal v-if="accessModalParams" :params="accessModalParams"
              @close="accessModalParams = null" @refresh="this.reloadingTable = true" />
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import DataTable from '../shared/datatable/table.vue';
import DescriptionRenderer from './renderers/description.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import CompletedTasksRenderer from './renderers/completed_tasks.vue';
import NameRenderer from './renderers/name.vue';
import DescriptionModal from './modals/description.vue';
import DuplicateModal from './modals/duplicate.vue';
import MoveModal from './modals/move.vue';
import EditModal from './modals/edit.vue';
import NewModal from './modals/new.vue';
import AccessModal from '../shared/access_modal/modal.vue';
import ExperimentCard from './card.vue';

export default {
  name: 'ExperimentsList',
  components: {
    DataTable,
    ConfirmationModal,
    DescriptionModal,
    DuplicateModal,
    MoveModal,
    EditModal,
    NewModal,
    AccessModal,
    ExperimentCard
  },
  props: {
    dataSource: { type: String, required: true },
    actionsUrl: { type: String, required: true },
    activePageUrl: { type: String },
    archivedPageUrl: { type: String },
    currentViewMode: { type: String, required: true },
    createUrl: { type: String, required: true },
    userRolesUrl: { type: String, required: true },
    archived: { type: Boolean }
  },
  data() {
    return {
      accessModalParams: null,
      newModalOpen: false,
      editModalObject: null,
      moveModalObject: null,
      duplicateModalObject: null,
      descriptionModalObject: null,
      reloadingTable: false
    };
  },
  computed: {
    columnDefs() {
      const columns = [
        {
          field: 'name',
          flex: 1,
          headerName: this.i18n.t('experiments.card.name'),
          sortable: true,
          cellRenderer: NameRenderer,
          minWidth: 150
        },
        {
          field: 'code',
          headerName: this.i18n.t('experiments.id'),
          sortable: true,
          minWidth: 80
        },
        {
          field: 'created_at',
          headerName: this.i18n.t('experiments.card.start_date'),
          sortable: true,
          minWidth: 110
        },
        {
          field: 'updated_at',
          headerName: this.i18n.t('experiments.card.modified_date'),
          sortable: true,
          minWidth: 110
        }
      ];

      if (this.currentViewMode === 'archived') {
        columns.push({
          field: 'archived_on',
          headerName: this.i18n.t('experiments.card.archived_date'),
          sortable: true
        });
      }

      columns.push({
        field: 'completed_tasks',
        headerName: this.i18n.t('experiments.card.completed_task'),
        cellRenderer: CompletedTasksRenderer,
        sortable: true,
        minWidth: 110
      });
      columns.push({
        field: 'description',
        headerName: this.i18n.t('experiments.card.description'),
        sortable: true,
        cellStyle: { 'white-space': 'normal' },
        cellRenderer: DescriptionRenderer,
        autoHeight: true,
        minWidth: 110
      });

      return columns;
    },
    viewRenders() {
      return [{ type: 'table' }, { type: 'cards' }];
    },
    toolbarActions() {
      const left = [];

      if (this.createUrl) {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('experiments.toolbar.new_button'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
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
        },
        {
          key: 'created_at',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.updated_on.label')
        }
      ];

      if (this.currentViewMode === 'archived') {
        filters.push({
          key: 'archived_on',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.archived_on.label')
        });
      }

      return filters;
    }
  },
  methods: {
    updateTable() {
      this.newModalOpen = false;
      this.editModalObject = null;
      this.moveModalObject = null;
      this.duplicateModalObject = null;
      this.descriptionModalObject = null;
      this.reloadingTable = true;
    },
    updateNavigator(withExpanedChildren = false) {
      window.navigatorContainer.reloadNavigator(withExpanedChildren);
    },
    async archive(event, rows) {
      axios.post(event.path, { experiment_ids: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.updateNavigator(false);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    restore(event, rows) {
      axios.post(event.path, { experiment_ids: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.updateNavigator(false);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    showDescription(_e, experiment) {
      [this.descriptionModalObject] = experiment;
    },
    duplicate(_e, experiment) {
      [this.duplicateModalObject] = experiment;
    },
    move(event, rows) {
      [this.moveModalObject] = rows;
      this.moveModalObject.movePath = event.path;
    },
    edit(_e, experiment) {
      [this.editModalObject] = experiment;
    },
    create() {
      this.newModalOpen = true;
    },
    access(event, rows) {
      this.accessModalParams = {
        object: rows[0],
        roles_path: this.userRolesUrl
      };
    }
  }
};
</script>
