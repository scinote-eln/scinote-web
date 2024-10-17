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
    @duplicate="duplicate"
    @editTags="editTags"/>

  <TagsModal v-if="tagsModalObject"
              :params="tagsModalObject"
              :tagsColors="tagsColors"
              :projectName="projectName"
              :projectTagsUrl="projectTagsUrl"
              @close="updateTable" />
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
import NameRenderer from './renderers/name.vue';
import ResultsRenderer from './renderers/results.vue';
import StatusRenderer from './renderers/status.vue';
import DueDateRenderer from './renderers/due_date.vue';
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
    archived: { type: Boolean }
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
      filters: []
    };
  },
  created() {
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
        field: 'due_date',
        headerName: this.i18n.t('experiments.table.column.due_date_html'),
        sortable: true,
        cellRenderer: DueDateRenderer,
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

      return {
        left,
        right: []
      };
    }
  },
  methods: {
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
