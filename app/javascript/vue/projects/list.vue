<template>
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
             :viewRenders="viewRenders"
             @tableReloaded="reloadingTable = false"
             @comments="openComments"
             @archive="archive"
             @restore="restore"
             @edit="edit"
             @create="create"
             @create_folder="createFolder"
             @delete_folders="deleteFolder"
             @export="exportProjects"
             @move="move"
  >
    <template #card="data">
      <ProjectCard :params="data.params" :dtComponent="data.dtComponent" ></ProjectCard>
    </template>
  </DataTable>
  <a href="#" ref="commentButton" class="open-comments-sidebar hidden" data-turbolinks="false" data-object-type="Project" data-object-id=""></a>
  <ConfirmationModal
    :title="i18n.t('projects.index.archive_confirm_title')"
    :description="i18n.t('projects.index.archive_confirm')"
    :confirmClass="'btn btn-primary'"
    :confirmText="i18n.t('general.archive')"
    ref="archiveModal"
  ></ConfirmationModal>
  <ConfirmationModal
    :title="i18n.t('projects.index.modal_delete_folders.title')"
    :description="folderDeleteDescription"
    :confirmClass="'btn btn-danger'"
    :confirmText="i18n.t('projects.index.modal_delete_folders.confirm_button')"
    ref="deleteFolderModal"
  ></ConfirmationModal>
  <ConfirmationModal
    :title="i18n.t('projects.export_projects.modal_title')"
    :description="exportDescription"
    :confirmClass="'btn btn-primary'"
    :confirmText="i18n.t('projects.export_projects.export_button')"
    ref="exportModal"
  ></ConfirmationModal>
  <EditProjectModal v-if="editProject" :userRolesUrl="userRolesUrl" :project="editProject" @close="editProject = null" @update="updateTable" />
  <EditFolderModal v-if="editFolder" :folder="editFolder" @close="editFolder = null" @update="updateTable" />
  <NewProjectModal v-if="newProject" :createUrl="createUrl" :currentFolderId="currentFolderId" :userRolesUrl="userRolesUrl" @close="newProject = false" @create="updateTable" />
  <NewFolderModal v-if="newFolder" :createFolderUrl="createFolderUrl" :currentFolderId="currentFolderId" :viewMode="currentViewMode" @close="newFolder = false" @create="updateTable" />
  <MoveModal v-if="objectsToMove" :moveToUrl="moveToUrl" :selectedObjects="objectsToMove" :foldersTreeUrl="foldersTreeUrl" @close="objectsToMove = null" @move="updateTable" />
</template>

<script>
import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue'
import UsersRenderer from './renderers/users.vue'
import ProjectCard from './card.vue'
import ConfirmationModal from '../shared/confirmation_modal.vue'
import EditProjectModal from './modals/edit.vue'
import EditFolderModal from './modals/edit_folder.vue'
import NewProjectModal from './modals/new.vue'
import NewFolderModal from './modals/new_folder.vue'
import MoveModal from './modals/move.vue'

export default {
  name: 'ProjectsList',
  components: {
    DataTable,
    UsersRenderer,
    ProjectCard,
    ConfirmationModal,
    EditProjectModal,
    EditFolderModal,
    NewProjectModal,
    NewFolderModal,
    MoveModal
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
    userRolesUrl: { type: String },
    currentFolderId: { type: String },
    foldersTreeUrl: { type: String },
    moveToUrl: { type: String },
  },
  data() {
    return {
      newProject: false,
      newFolder: false,
      editProject: null,
      editFolder: null,
      objectsToMove: null,
      reloadingTable: false,
      folderDeleteDescription: '',
      exportDescription: '',
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
    viewRenders() {
      return [
        {type: 'table'},
        {type: 'cards'}
      ]
    },
    toolbarActions() {
      let left = []
      if (this.createUrl && this.currentViewMode !== 'archived') {
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
        key: 'members',
        type: 'Select',
        optionsUrl: this.usersFilterUrl,
        optionRenderer: this.usersFilterRenderer,
        labelRenderer: this.usersFilterRenderer,
        label: this.i18n.t("projects.index.filters_modal.members.label"),
        placeholder: this.i18n.t("projects.index.filters_modal.members.placeholder"),
      })

      filters.push({
        key: 'folder_search',
        type: 'Checkbox',
        label: this.i18n.t("projects.index.filters_modal.folders.label"),
      })

      return filters
    }
  },
  methods: {
    usersFilterRenderer(option) {
      return `<div class="flex items-center gap-2">
                <img src="${option[2].avatar_url}" class="rounded-full w-6 h-6" />
                <span>${option[1]}</span>
              </div>`
    },
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
    openComments(_params, rows) {
      this.$refs.commentButton.dataset.objectId = rows[0].id;
      this.$refs.commentButton.click();
    },
    async archive(event, rows) {
      const ok = await this.$refs.archiveModal.show()
      if (ok) {
        axios.post(event.path, { project_ids: rows.map((row) => row.id) }).then((response) => {
          this.reloadingTable = true
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
    restore(event, rows) {
      axios.post(event.path, { project_ids: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    edit(event, rows) {
      if (rows[0].folder) {
        this.editFolder = rows[0]
        return
      }
      this.editProject = rows[0]
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
    },
    async deleteFolder(event, rows) {
      const description =`
        <p>${this.i18n.t('projects.index.modal_delete_folders.description_1_html', {number: rows.length}) }</p>
        <p>${this.i18n.t('projects.index.modal_delete_folders.description_2')}</p>`
      this.folderDeleteDescription = description;
      const ok = await this.$refs.deleteFolderModal.show();
      if (ok) {
        axios.post(event.path, { project_folder_ids: rows.map((row) => row.id) }).then((response) => {
          this.reloadingTable = true
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
    async exportProjects(event, rows) {
      this.exportDescription = event.message;
      const ok = await this.$refs.exportModal.show()
      if (ok) {
        axios.post(event.path, {
          project_ids: rows.filter((row) => !row.folder).map((row) => row.id),
          project_folder_ids: rows.filter((row) => row.folder).map((row) => row.id),
        }).then((response) => {
          this.reloadingTable = true
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
    move(event, rows) {
      this.objectsToMove = rows;
    }
  }
}

</script>