<template>
  <DataTable
    ref="list"
    :columnDefs="columnDefs"
    tableId="MyModuleList"
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
    :hiddenDataMessage="i18n.t('experiments.empty_state.no_active_modules_archived_branch')"
    scrollMode="infinite"
    @tableReloaded="reloadingTable = false"
    @reloadTable="reloadingTable = true"
    @create="newModalOpen = true"
    @edit="edit"
    @move="move"
    @access="access"
    @archive="archive"
    @restore="restore"
    @showExperimentDescription="showExperimentDescription = true"
    @duplicate="duplicate"
    @updateDueDate="updateDueDate"
    @updateStartDate="updateStartDate"
    @editTags="editTags"/>

  <TagsModal v-if="tagsModalObject"
              :params="tagsModalObject"
              :tagsColors="tagsColors"
              :projectName="projectName"
              :projectTagsUrl="projectTagsUrl"
              @close="updateTable" />
  <ExperimentDescriptionModal
    v-if="experiment && showExperimentDescription"
    :object="experiment.attributes"
    @update="updateExperimentDescription"
    @close="showExperimentDescription = false"/>
  <NewModal v-if="newModalOpen"
            :createUrl="createUrl"
            :projectTagsUrl="projectTagsUrl"
            :assignedUsersUrl="assignedUsersUrl"
            :currentUserId="currentUserId"
            @create="updateTable"
            @close="newModalOpen = false" />
  <EditModal v-if="editModalObject"
             :my_module="editModalObject"
             @close="editModalObject = null"
             @update="updateTable" />
  <MoveModal v-if="moveModalObject"
             :my_module="moveModalObject"
             @close="moveModalObject = null"
             @move="updateTable" />
  <AccessModal v-if="accessModalParams" :params="accessModalParams"
               @close="accessModalParams = null" @refresh="this.reloadingTable = true" />
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import DataTable from '../shared/datatable/table.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import ExperimentDescriptionModal from '../shared/datatable/modals/description.vue';
import NameRenderer from './renderers/name.vue';
import ResultsRenderer from './renderers/results.vue';
import StatusRenderer from './renderers/status.vue';
import DueDateRenderer from '../shared/datatable/renderers/date.vue';
import StartDateRenderer from '../shared/datatable/renderers/date.vue';
import DesignatedUsers from './renderers/designated_users.vue';
import TagsModal from './modals/tags.vue';
import TagsRenderer from './renderers/tags.vue';
import CommentsRenderer from '../shared/datatable/renderers/comments.vue';
import NewModal from './modals/new.vue';
import EditModal from './modals/edit.vue';
import MoveModal from './modals/move.vue';
import AccessModal from '../shared/access_modal/modal.vue';

export default {
  name: 'MyModulesList',
  components: {
    DataTable,
    ConfirmationModal,
    DueDateRenderer,
    ExperimentDescriptionModal,
    StartDateRenderer,
    DesignatedUsers,
    TagsModal,
    NewModal,
    EditModal,
    MoveModal,
    AccessModal,
    NameRenderer,
    ResultsRenderer,
    StatusRenderer
  },
  props: {
    dataSource: { type: String, required: true },
    actionsUrl: { type: String, required: true },
    activePageUrl: { type: String },
    archivedPageUrl: { type: String },
    currentViewMode: { type: String, required: true },
    currentUserId: { type: String, required: true },
    createUrl: { type: String, required: true },
    userRolesUrl: { type: String, required: true },
    canvasUrl: { type: String, required: true },
    tagsColors: { type: Array, required: true },
    projectTagsUrl: { type: String, required: true },
    assignedUsersUrl: { type: String, required: true },
    usersFilterUrl: { type: String, required: true },
    statusesList: { type: Array, required: true },
    projectName: { type: String },
    archived: { type: Boolean },
    experimentUrl: { type: String, required: true }
  },
  data() {
    return {
      moveModalObject: null,
      editModalObject: null,
      newModalOpen: false,
      tagsModalObject: null,
      reloadingTable: false,
      accessModalParams: null,
      columnDefs: [],
      filters: [],
      showExperimentDescription: false,
      experiment: null
    };
  },
  created() {
    this.loadExperiment();

    const columns = [
      {
        field: 'name',
        headerName: this.i18n.t('experiments.table.column.task_name_html'),
        sortable: true,
        cellRenderer: NameRenderer
      },
      {
        field: 'code',
        headerName: this.i18n.t('experiments.table.column.id_html'),
        sortable: true
      },
      {
        field: 'start_date',
        headerName: this.i18n.t('experiments.table.column.start_date_html'),
        sortable: true,
        cellRenderer: StartDateRenderer,
        cellRendererParams: {
          placeholder: this.i18n.t('my_modules.details.no_start_date_placeholder'),
          field: 'start_date_cell',
          mode: 'datetime',
          emptyPlaceholder: this.i18n.t('my_modules.details.no_due_date'),
          emitAction: 'updateStartDate'
        },
        minWidth: 200
      },
      {
        field: 'due_date',
        headerName: this.i18n.t('experiments.table.column.due_date_html'),
        sortable: true,
        cellRenderer: DueDateRenderer,
        cellRendererParams: {
          placeholder: this.i18n.t('my_modules.details.no_due_date_placeholder'),
          field: 'due_date_cell',
          mode: 'datetime',
          emptyPlaceholder: this.i18n.t('my_modules.details.no_due_date'),
          emitAction: 'updateDueDate'
        },
        minWidth: 200
      },
      {
        field: 'results',
        headerName: this.i18n.t('experiments.table.column.results_html'),
        sortable: true,
        cellRenderer: ResultsRenderer
      },
      {
        field: 'age',
        headerName: this.i18n.t('experiments.table.column.age_html'),
        sortable: true
      },
      {
        field: 'status',
        headerName: this.i18n.t('experiments.table.column.status_html'),
        sortable: true,
        cellRenderer: StatusRenderer,
        minWidth: 120
      }
    ];

    if (this.currentViewMode === 'archived') {
      columns.push({
        field: 'archived_on',
        headerName: this.i18n.t('experiments.table.column.archived_html'),
        sortable: true
      });
    }

    columns.push({
      field: 'designated',
      headerName: this.i18n.t('experiments.table.column.assigned_html'),
      sortable: true,
      cellRenderer: DesignatedUsers,
      minWidth: 220
    });
    columns.push({
      field: 'tags',
      headerName: this.i18n.t('experiments.table.column.tags_html'),
      sortable: true,
      cellRenderer: TagsRenderer,
      minWidth: 180
    });
    columns.push({
      field: 'comments',
      headerName: this.i18n.t('experiments.table.column.comments_html'),
      sortable: true,
      cellRenderer: CommentsRenderer,
      notSelectable: true
    });

    if (window.externalMyModuleColumns) {
      window.externalMyModuleColumns.forEach((column) => {
        if (columns.find((c) => c.field === column.field)) {
          const index = columns.findIndex((c) => c.field === column.field);
          columns[index] = column;
        } else {
          columns.push(column);
        }
      });
    }

    const filters = [
      {
        key: 'query',
        type: 'Text'
      },
      {
        key: 'due_date',
        type: 'DateRange',
        label: this.i18n.t('experiments.table.filters.due_date')
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
      key: 'designated_users',
      type: 'Select',
      optionsUrl: this.usersFilterUrl,
      optionRenderer: this.usersFilterRenderer,
      labelRenderer: this.usersFilterRenderer,
      label: this.i18n.t('experiments.table.filters.assigned'),
      placeholder: this.i18n.t('experiments.table.filters.assigned_placeholder')
    });

    filters.push({
      key: 'statuses',
      type: 'Select',
      options: this.statusesList,
      label: this.i18n.t('experiments.table.filters.status'),
      placeholder: this.i18n.t('experiments.table.filters.status_placeholder')
    });

    this.columnDefs = columns;
    this.filters = filters;
  },
  mounted() {
    window.myModulesList = this;
  },
  computed: {
    viewRenders() {
      const canvasLabel = this.currentViewMode === 'active'
        ? this.i18n.t('toolbar.canvas_view') : this.i18n.t('toolbar.cards_view');
      return [
        { type: 'table' },
        {
          type: 'custom',
          name: canvasLabel,
          url: this.canvasUrl
        }
      ];
    },
    toolbarActions() {
      const left = [];

      if (this.createUrl && this.currentViewMode !== 'archived') {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('experiments.table.toolbar.new'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
        });
      }

      left.push({
        name: 'showExperimentDescription',
        icon: 'sn-icon sn-icon-info',
        label: this.i18n.t('experiments.toolbar.description_button'),
        type: 'emit',
        buttonStyle: 'btn btn-light'
      });

      return {
        left,
        right: []
      };
    }
  },
  methods: {
    loadExperiment() {
      axios.get(this.experimentUrl).then((response) => {
        this.experiment = response.data.data;
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    updateDueDate(value, params) {
      axios.put(params.data.urls.update_due_date, {
        my_module: {
          due_date: this.formatDate(value)
        }
      }).then(() => {
        this.updateTable();
      });
    },
    updateExperimentDescription(description) {
      axios.put(this.experiment.attributes.urls.update, {
        experiment: {
          description
        }
      }).then(() => {
        this.loadExperiment();
      });
    },
    updateStartDate(value, params) {
      axios.put(params.data.urls.update_start_date, {
        my_module: {
          started_on: this.formatDate(value)
        }
      }).then(() => {
        this.updateTable();
      });
    },
    formatDate(date) {
      if (!(date instanceof Date)) return null;

      const y = date.getFullYear();
      const m = date.getMonth() + 1;
      const d = date.getDate();
      const hours = date.getHours();
      const mins = date.getMinutes();
      return `${y}/${m}/${d} ${hours}:${mins}`;
    },
    updateTable() {
      this.tagsModalObject = null;
      this.newModalOpen = false;
      this.reloadingTable = true;
      this.editModalObject = null;
      this.moveModalObject = null;
      this.updateNavigator(true);
    },
    updateNavigator(withExpanedChildren = false) {
      window.navigatorContainer.reloadNavigator(withExpanedChildren);
    },
    async archive(event, rows) {
      axios.post(event.path, { my_modules: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.updateNavigator(true);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    restore(event, rows) {
      axios.post(event.path, { my_modules_ids: rows.map((row) => row.id), view: 'table' }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.updateNavigator(true);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    editTags(_e, rows) {
      [this.tagsModalObject] = rows;
    },
    edit(_e, rows) {
      [this.editModalObject] = rows;
    },
    move(event, rows) {
      [this.moveModalObject] = rows;
      this.moveModalObject.movePath = event.path;
    },
    duplicate(event, rows) {
      axios.post(event.path, { my_module_ids: rows.map((row) => row.id) }).then(() => {
        this.reloadingTable = true;
        this.updateNavigator(true);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    access(_event, rows) {
      this.accessModalParams = {
        object: rows[0],
        roles_path: this.userRolesUrl
      };
    },
    usersFilterRenderer(option) {
      return `<div class="flex items-center gap-2">
                <img src="${option[2].avatar_url}" class="rounded-full w-6 h-6" />
                <span title="${option[1]}" class="truncate">${option[1]}</span>
              </div>`;
    }
  }
};
</script>
