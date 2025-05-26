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
    :tableOnly="true"
    :objectArchived="archived"
    :hiddenDataMessage="i18n.t('projects.show.empty_state.no_active_experiment_archived_project')"
    scrollMode="infinite"
    @tableReloaded="reloadingTable = false"
    @archive="archive"
    @restore="restore"
    @showDescription="showDescription"
    @showProjectDescription="showProjectDescription = true"
    @duplicate="duplicate"
    @move="move"
    @edit="edit"
    @create="create"
    @access="access"
    @updateDueDate="updateDueDate"
    @updateStartDate="updateStartDate"
    @changeStatus="changeStatus"
    @updateFavorite="updateFavorite"
  >
    <template #card="data">
      <ExperimentCard :params="data.params" :dtComponent="data.dtComponent" ></ExperimentCard>
    </template>
  </DataTable>

  <DescriptionModal
    v-if="descriptionModalObject"
    :object="descriptionModalObject"
    @update="updateDescription"
    @close="descriptionModalObject = null"/>
  <ProjectDescriptionModal
    v-if="project && showProjectDescription"
    :object="project.attributes"
    @update="updateProjectDescription"
    @close="showProjectDescription = false"/>
  <DuplicateModal
    v-if="duplicateModalObject"
    :experiment="duplicateModalObject"
    @close="duplicateModalObject = null"/>
  <MoveModal
    v-if="moveModalObject"
    :experiment="moveModalObject"
    @close="moveModalObject = null"
    @move="updateTable"/>
  <ExperimentFormModal
    v-if="editModalObject"
    :experiment="editModalObject"
    @close="editModalObject = null"
    @update="updateTable"/>
  <ExperimentFormModal
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
import DescriptionRenderer from '../shared/datatable/renderers/description.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import CompletedTasksRenderer from './renderers/completed_tasks.vue';
import NameRenderer from './renderers/name.vue';
import DescriptionModal from '../shared/datatable/modals/description.vue';
import ProjectDescriptionModal from '../shared/datatable/modals/description.vue';
import DuplicateModal from './modals/duplicate.vue';
import MoveModal from './modals/move.vue';
import ExperimentFormModal from './modals/form.vue';
import AccessModal from '../shared/access_modal/modal.vue';
import StatusRenderer from './renderers/status.vue';
import DueDateRenderer from '../shared/datatable/renderers/date.vue';
import StartDateRenderer from '../shared/datatable/renderers/date.vue';
import ExperimentCard from './card.vue';
import FavoriteRenderer from '../shared/datatable/renderers/favorite.vue';

export default {
  name: 'ExperimentsList',
  components: {
    DataTable,
    ConfirmationModal,
    DescriptionModal,
    ProjectDescriptionModal,
    DuplicateModal,
    MoveModal,
    ExperimentFormModal,
    AccessModal,
    ExperimentCard,
    StatusRenderer,
    StartDateRenderer,
    DueDateRenderer,
    FavoriteRenderer
  },
  props: {
    dataSource: { type: String, required: true },
    actionsUrl: { type: String, required: true },
    activePageUrl: { type: String },
    archivedPageUrl: { type: String },
    currentViewMode: { type: String, required: true },
    createUrl: { type: String, required: true },
    userRolesUrl: { type: String, required: true },
    archived: { type: Boolean },
    projectUrl: { type: String, required: true }
  },
  data() {
    return {
      accessModalParams: null,
      newModalOpen: false,
      editModalObject: null,
      moveModalObject: null,
      duplicateModalObject: null,
      descriptionModalObject: null,
      showProjectDescription: false,
      project: null,
      reloadingTable: false,
      statusesList: [
        ['not_started', this.i18n.t('experiments.table.column.status.not_started')],
        ['started', this.i18n.t('experiments.table.column.status.started')],
        ['completed', this.i18n.t('experiments.table.column.status.completed')]
      ]
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
          field: 'favorite',
          headerComponentParams: {
            html: '<div class="sn-icon sn-icon-star-filled"></div>'
          },
          headerName: this.i18n.t('experiments.table.column.favorite'),
          sortable: true,
          cellRenderer: FavoriteRenderer,
          minWidth: 70,
          maxWidth: 70,
          notSelectable: true
        },
        {
          field: 'code',
          headerName: this.i18n.t('experiments.id'),
          sortable: true,
          minWidth: 80
        },
        {
          field: 'status',
          headerName: this.i18n.t('experiments.table.column.status_html'),
          sortable: true,
          cellRenderer: StatusRenderer,
          cellRendererParams: {
            statusesList: this.statusesList
          },
          minWidth: 180
        },
        {
          field: 'start_date',
          headerName: this.i18n.t('experiments.table.column.start_date_html'),
          sortable: true,
          cellRenderer: StartDateRenderer,
          cellRendererParams: {
            placeholder: this.i18n.t('experiments.table.column.no_start_date_placeholder'),
            field: 'start_date_cell',
            mode: 'date',
            emptyPlaceholder: this.i18n.t('experiments.table.column.no_due_date'),
            emitAction: 'updateStartDate'
          },
          minWidth: 180
        },
        {
          field: 'due_date',
          headerName: this.i18n.t('experiments.table.column.due_date_html'),
          sortable: true,
          cellRenderer: DueDateRenderer,
          cellRendererParams: {
            placeholder: this.i18n.t('experiments.table.column.no_due_date_placeholder'),
            field: 'due_date_cell',
            mode: 'date',
            emptyPlaceholder: this.i18n.t('experiments.table.column.no_due_date'),
            emitAction: 'updateDueDate'
          },
          minWidth: 200
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
        headerName: this.i18n.t('experiments.table.column.completed_task'),
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

      left.push({
        name: 'showProjectDescription',
        icon: 'sn-icon sn-icon-info',
        label: this.i18n.t('experiments.toolbar.description_button'),
        type: 'emit',
        buttonStyle: 'btn btn-light'
      });

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
          key: 'start_on',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.created_on.label'),
          mode: 'date'
        },
        {
          key: 'due_date',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.due_date.label'),
          mode: 'date'
        },
        {
          key: 'updated_on',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.updated_on.label')
        },
        {
          key: 'statuses',
          type: 'Select',
          options: this.statusesList,
          label: this.i18n.t('experiments.index.filters.status'),
          placeholder: this.i18n.t('experiments.index.filters.status_placeholder')
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
  created() {
    this.loadProject();
  },
  methods: {
    loadProject() {
      axios.get(this.projectUrl).then((response) => {
        this.project = response.data.data;
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
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
    updateDescription(description) {
      axios.put(this.descriptionModalObject.urls.update, {
        experiment: {
          description
        }
      }).then(() => {
        this.updateTable();
      });
    },
    updateProjectDescription(description) {
      axios.put(this.project.attributes.urls.update, {
        project: {
          description
        }
      }).then(() => {
        this.loadProject();
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
    },
    formatDate(date) {
      if (!(date instanceof Date)) return null;

      const y = date.getFullYear();
      const m = date.getMonth() + 1;
      const d = date.getDate();

      return `${y}/${m}/${d}`;
    },
    updateField(url, params) {
      axios.put(url, params).then(() => {
        this.updateTable();
      });
    },
    changeStatus(value, params) {
      this.updateField(params.data.urls.update, { experiment: { status: value } });
    },
    updateDueDate(value, params) {
      this.updateField(params.data.urls.update, { due_date: this.formatDate(value) });
    },
    updateStartDate(value, params) {
      this.updateField(params.data.urls.update, { start_on: this.formatDate(value) });
    },
    updateFavorite(value, params) {
      const url = value ? params.data.urls.favorite : params.data.urls.unfavorite;
      axios.post(url).then(() => {
        this.updateTable();
      });
    }
  }
};
</script>
