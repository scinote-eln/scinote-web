<template>
  <DataTable :columnDefs="columnDefs"
             tableId="ProjectList"
             :dataUrl="dataSource"
             :reloadingTable="reloadingTable"
             :toolbarActions="toolbarActions"
             :actionsUrl="actionsUrl"
             :activePageUrl="activePageUrl"
             :archivedPageUrl="archivedPageUrl"
             :currentViewMode="currentViewMode"
             scrollMode="infinite"
             :filters="filters"
             :tableOnly="true"
             @tableReloaded="reloadingTable = false"
             @comments="openComments"
             @archive="archive"
             @restore="restore"
             @edit="edit"
             @create="create"
             @create_folder="createFolder"
             @delete_folders="deleteFolder"
             @export="exportProjects"
             @showDescription="showDescription"
             @changeStatus="changeStatus"
             @changeSuperviser="changeSuperviser"
             @move="move"
             @access="access"
             @updateDueDate="updateDueDate"
             @updateStartDate="updateStartDate"
             @updateFavorite="updateFavorite"
  >
    <template #card="data">
      <ProjectCard :params="data.params" :dtComponent="data.dtComponent" ></ProjectCard>
    </template>
  </DataTable>
  <a href="#" ref="commentButton" class="open-comments-sidebar hidden"
     data-turbolinks="false" data-object-type="Project" data-object-id=""></a>
  <ConfirmationModal
    :title="i18n.t('projects.index.modal_delete_folders.title')"
    :description="folderDeleteDescription"
    confirmClass="btn btn-danger"
    :confirmText="i18n.t('projects.index.modal_delete_folders.confirm_button')"
    ref="deleteFolderModal"
  ></ConfirmationModal>
  <ConfirmationModal
    :title="i18n.t('projects.export_projects.modal_title')"
    :description="exportDescription"
    confirmClass="btn btn-primary"
    :confirmText="i18n.t('projects.export_projects.export_button')"
    ref="exportModal"
  ></ConfirmationModal>
  <DescriptionModal
    v-if="descriptionModalObject"
    :object="descriptionModalObject"
    @update="updateDescription"
    @close="descriptionModalObject = null"/>
  <ExportLimitExceededModal v-if="exportLimitExceded" :description="exportDescription" @close="exportLimitExceded = false"/>
  <ProjectFormModal v-if="editProject" :userRolesUrl="userRolesUrl"
                    :project="editProject" @close="editProject = null" @update="updateTable(); updateNavigator()" />
  <EditFolderModal v-if="editFolder" :folder="editFolder"
                   @close="editFolder = null" @update="updateTable(); updateNavigator()" />
  <ProjectFormModal v-if="newProject" :createUrl="createUrl"
                   :currentFolderId="currentFolderId" :userRolesUrl="userRolesUrl"
                   @close="newProject = false" @create="updateTable(); updateNavigator()" />
  <NewFolderModal v-if="newFolder" :createFolderUrl="createFolderUrl"
                  :currentFolderId="currentFolderId" :viewMode="currentViewMode"
                  @close="newFolder = false" @create="updateTable(); updateNavigator()" />
  <MoveModal v-if="objectsToMove" :moveToUrl="moveToUrl"
             :selectedObjects="objectsToMove" :foldersTreeUrl="foldersTreeUrl"
             @close="objectsToMove = null" @move="updateTable(); updateNavigator(true)" />
  <AccessModal v-if="accessModalParams" :params="accessModalParams"
               @close="accessModalParams = null" @refresh="this.reloadingTable = true" />
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import UsersRenderer from './renderers/users.vue';
import NameRenderer from './renderers/name.vue';
import StatusRenderer from './renderers/status.vue';
import SuperviserRenderer from './renderers/superviser.vue';
import CommentsRenderer from '../shared/datatable/renderers/comments.vue';
import DueDateRenderer from '../shared/datatable/renderers/date.vue';
import DescriptionRenderer from '../shared/datatable/renderers/description.vue';
import DescriptionModal from '../shared/datatable/modals/description.vue';
import ProjectCard from './card.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import ProjectFormModal from './modals/form.vue';
import EditFolderModal from './modals/edit_folder.vue';
import NewFolderModal from './modals/new_folder.vue';
import MoveModal from './modals/move.vue';
import AccessModal from '../shared/access_modal/modal.vue';
import ExportLimitExceededModal from './modals/export_limit_exceeded_modal.vue';
import FavoriteRenderer from '../shared/datatable/renderers/favorite.vue';
import { max } from 'lodash';

export default {
  name: 'ProjectsList',
  components: {
    DataTable,
    UsersRenderer,
    NameRenderer,
    ProjectCard,
    ConfirmationModal,
    ProjectFormModal,
    EditFolderModal,
    NewFolderModal,
    MoveModal,
    AccessModal,
    ExportLimitExceededModal,
    DueDateRenderer,
    DescriptionRenderer,
    DescriptionModal,
    StatusRenderer,
    SuperviserRenderer,
    FavoriteRenderer
  },
  props: {
    dataSource: { type: String, required: true },
    actionsUrl: { type: String, required: true },
    createUrl: { type: String },
    createFolderUrl: { type: String },
    activePageUrl: { type: String },
    archivedPageUrl: { type: String },
    currentViewMode: { type: String, required: true },
    usersFilterUrl: { type: String },
    headOfProjectUsersListUrl: { type: String },
    userRolesUrl: { type: String },
    currentFolderId: { type: String },
    foldersTreeUrl: { type: String },
    moveToUrl: { type: String }
  },
  data() {
    return {
      accessModalParams: null,
      newProject: false,
      newFolder: false,
      editProject: null,
      editFolder: null,
      objectsToMove: null,
      reloadingTable: false,
      exportLimitExceded: false,
      folderDeleteDescription: '',
      exportDescription: '',
      descriptionModalObject: null,
      statusesList: [
        ['not_started', this.i18n.t('projects.index.status.not_started')],
        ['started', this.i18n.t('projects.index.status.started')],
        ['completed', this.i18n.t('projects.index.status.completed')]
      ]
    };
  },
  computed: {
    columnDefs() {
      const columns = [{
        field: 'name',
        flex: 1,
        headerName: this.i18n.t('projects.index.card.name'),
        sortable: true,
        cellRenderer: 'NameRenderer'
      },
      {
        field: 'favorite',
        headerComponentParams: {
          html: '<div class="sn-icon sn-icon-star-filled"></div>'
        },
        headerName: this.i18n.t('projects.index.favorite'),
        sortable: true,
        cellRenderer: FavoriteRenderer,
        minWidth: 70,
        maxWidth: 70,
        notSelectable: true
      },
      {
        field: 'code',
        headerName: this.i18n.t('projects.index.card.id'),
        sortable: true
      },
      {
        field: 'status',
        headerName: this.i18n.t('projects.index.card.status'),
        sortable: true,
        cellRenderer: StatusRenderer,
        cellRendererParams: {
          statusesList: this.statusesList
        },
        notSelectable: true,
        minWidth: 180
      },
      {
        field: 'due_date',
        headerName: this.i18n.t('projects.index.due_date'),
        sortable: true,
        cellRenderer: DueDateRenderer,
        cellRendererParams: {
          placeholder: this.i18n.t('projects.index.add_due_date'),
          field: 'due_date_cell',
          mode: 'date',
          emptyPlaceholder: this.i18n.t('projects.index.no_due_date'),
          emitAction: 'updateDueDate'
        },
        minWidth: 200,
        notSelectable: true
      },
      {
        field: 'start_on',
        headerName: this.i18n.t('projects.index.start_date'),
        sortable: true,
        cellRenderer: DueDateRenderer,
        cellRendererParams: {
          placeholder: this.i18n.t('projects.index.add_start_date'),
          field: 'start_on_cell',
          mode: 'date',
          emptyPlaceholder: this.i18n.t('projects.index.no_start_date'),
          emitAction: 'updateStartDate'
        },
        minWidth: 200,
        notSelectable: true
      },
      {
        field: 'supervised_by',
        headerName: this.i18n.t('projects.index.card.supervised_by'),
        sortable: true,
        cellRenderer: SuperviserRenderer,
        notSelectable: true
      },
      {
        field: 'created_at',
        headerName: this.i18n.t('projects.index.card.start_date'),
        sortable: true
      },
      {
        field: 'updated_at',
        headerName: this.i18n.t('projects.index.card.updated_at'),
        sortable: true
      },
      {
        field: 'users',
        headerName: this.i18n.t('projects.index.card.users'),
        cellRenderer: 'UsersRenderer',
        sortable: true,
        minWidth: 210,
        notSelectable: true
      },
      {
        field: 'comments',
        headerName: this.i18n.t('projects.index.card.comments'),
        sortable: true,
        cellRenderer: CommentsRenderer,
        notSelectable: true
      },
      {
        field: 'description',
        headerName: this.i18n.t('projects.index.card.description'),
        sortable: true,
        cellStyle: { 'white-space': 'normal' },
        cellRenderer: 'DescriptionRenderer',
        autoHeight: true,
        minWidth: 110
      }];
      if (this.currentViewMode === 'archived') {
        columns.push({
          field: 'archived_on',
          headerName: this.i18n.t('projects.index.card.archived_date'),
          sortable: true
        });
      }

      return columns;
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
        key: 'head_of_project',
        type: 'Select',
        optionsUrl: this.headOfProjectUsersListUrl,
        optionRenderer: this.usersFilterRenderer,
        labelRenderer: this.usersFilterRenderer,
        label: this.i18n.t('projects.index.filters_modal.head_of_project.label'),
        placeholder: this.i18n.t('projects.index.filters_modal.head_of_project.placeholder')
      });

      filters.push({
        key: 'statuses',
        type: 'Select',
        options: this.statusesList,
        label: this.i18n.t('projects.index.filters_modal.status.label'),
        placeholder: this.i18n.t('projects.index.filters_modal.status.placeholder')
      });

      filters.push({
        key: 'folder_search',
        type: 'Checkbox',
        label: this.i18n.t('projects.index.filters_modal.folders.label')
      });

      return filters;
    }
  },
  methods: {
    updateDueDate(value, params) {
      axios.put(params.data.urls.update, {
        project: {
          due_date: this.formatDate(value)
        }
      }).then(() => {
        this.updateTable();
      });
    },
    updateStartDate(value, params) {
      axios.put(params.data.urls.update, {
        project: {
          start_on: this.formatDate(value)
        }
      }).then(() => {
        this.updateTable();
      });
    },
    updateFavorite(value, params) {
      const url = value ? params.data.urls.favorite : params.data.urls.unfavorite;
      axios.post(url).then(() => {
        this.updateTable();
      });
    },
    showDescription(_e, project) {
      [this.descriptionModalObject] = project;
    },
    updateDescription(description) {
      axios.put(this.descriptionModalObject.urls.update, {
        project: {
          description
        }
      }).then(() => {
        this.updateTable();
      });
    },
    changeStatus(newStatus, params) {
      axios.put(params.data.urls.update, {
        project: {
          status: newStatus
        }
      }).then(() => {
        this.updateTable();
      });
    },
    changeSuperviser(newSuperviser, params) {
      axios.put(params.data.urls.update, {
        project: {
          supervised_by_id: newSuperviser[0]
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
      return `${y}/${m}/${d}`;
    },
    usersFilterRenderer(option) {
      return `<div class="flex items-center gap-2">
                <img src="${option[2].avatar_url}" class="rounded-full w-6 h-6" />
                <span title="${option[1]}" class="truncate">${option[1]}</span>
              </div>`;
    },
    openComments(_params, rows) {
      $(this.$refs.commentButton).data('objectId', rows[0].id);
      this.$refs.commentButton.click();
    },
    access(event, rows) {
      this.accessModalParams = {
        object: rows[0],
        roles_path: this.userRolesUrl
      };
    },
    async archive(event, rows) {
      axios.post(event.path, { project_ids: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.updateNavigator(false);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    restore(event, rows) {
      axios.post(event.path, { project_ids: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.updateNavigator(false);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    edit(event, rows) {
      if (rows[0].folder) {
        [this.editFolder] = rows;
        return;
      }
      [this.editProject] = rows;
    },
    create() {
      this.newProject = true;
    },
    createFolder() {
      this.newFolder = true;
    },
    updateTable() {
      this.editProject = null;
      this.editFolder = null;
      this.newProject = false;
      this.newFolder = false;
      this.objectsToMove = null;
      this.reloadingTable = true;
      this.exportLimitExceded = false;
    },
    updateNavigator(withExpanedChildren = false) {
      window.navigatorContainer.reloadNavigator(withExpanedChildren);
    },
    async deleteFolder(event, rows) {
      const description = `
        <p>${this.i18n.t('projects.index.modal_delete_folders.description_1_html', { number: rows.length })}</p>
        <p>${this.i18n.t('projects.index.modal_delete_folders.description_2')}</p>`;
      this.folderDeleteDescription = description;
      const ok = await this.$refs.deleteFolderModal.show();
      if (ok) {
        axios.post(event.path, { project_folder_ids: rows.map((row) => row.id) }).then((response) => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
    async exportProjects(event, rows) {
      if (event.number_of_projects === 0) {
        HelperModule.flashAlertMsg(this.i18n.t('projects.export_projects.zero_projects_flash'), 'danger');
      } else if (event.number_of_request_left > 0) {
        this.exportDescription = event.message;
        const ok = await this.$refs.exportModal.show();
        if (ok) {
          axios.post(event.path, {
            project_ids: rows.filter((row) => !row.folder).map((row) => row.id),
            project_folder_ids: rows.filter((row) => row.folder).map((row) => row.id)
          }).then((response) => {
            this.reloadingTable = true;
            HelperModule.flashAlertMsg(response.data.flash, 'success');
          }).catch((error) => {
            HelperModule.flashAlertMsg(error.response.data.error, 'danger');
          });
        }
      } else {
        this.exportDescription = event.message;
        this.exportLimitExceded = true;
      }
    },
    move(event, rows) {
      this.objectsToMove = rows;
    }
  }
};

</script>
