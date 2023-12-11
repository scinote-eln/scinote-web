<template>
  <DataTable
    :columnDefs="columnDefs"
    tableId="ExperimentsList"
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
    @archive="archive"
    @restore="restore"
    @showDescription="showDescription"
    @duplicate="duplicate"
    @move="move"
    @edit="edit"
  >
    <template> </template>
  </DataTable>

  <ConfirmationModal
    :title="i18n.t('experiments.index.archive_confirm_title')"
    :description="i18n.t('experiments.index.archive_confirm')"
    :confirmClass="'btn btn-primary'"
    :confirmText="i18n.t('general.archive')"
    ref="archiveModal"
  ></ConfirmationModal>
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

export default {
  name: 'ExperimentsList',
  components: {
    DataTable,
    ConfirmationModal,
    DescriptionModal,
    DuplicateModal,
    MoveModal,
    EditModal,
  },
  props: {
    dataSource: { type: String, required: true },
    actionsUrl: { type: String, required: true },
    activePageUrl: { type: String },
    archivedPageUrl: { type: String },
    currentViewMode: { type: String, required: true },
  },
  data() {
    return {
      editModalObject: null,
      moveModalObject: null,
      duplicateModalObject: null,
      descriptionModalObject: null,
      reloadingTable: false,
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
        },
        {
          field: 'code',
          headerName: this.i18n.t('experiments.id'),
          sortable: true,
        },
        {
          field: 'created_at',
          headerName: this.i18n.t('experiments.card.start_date'),
          sortable: true,
        },
        {
          field: 'updated_at',
          headerName: this.i18n.t('experiments.card.modified_date'),
          sortable: true,
        },
      ];

      if (this.currentViewMode === 'archived') {
        columns.push({
          field: 'archived_on',
          headerName: this.i18n.t('experiments.card.archived_date'),
          sortable: true,
        });
      }

      columns.push({
        field: 'total_tasks',
        headerName: this.i18n.t('experiments.card.completed_task'),
        cellRenderer: CompletedTasksRenderer,
        sortable: false,
        minWidth: 120,
      });
      columns.push({
        field: 'description',
        headerName: this.i18n.t('experiments.card.description'),
        sortable: false,
        cellStyle: { 'white-space': 'normal' },
        cellRenderer: DescriptionRenderer,
        autoHeight: true,
      });

      return columns;
    },
    viewRenders() {
      return [{ type: 'table' }, { type: 'cards' }];
    },
    toolbarActions() {
      const left = [];

      left.push({
        name: 'create',
        icon: 'sn-icon sn-icon-new-task',
        label: this.i18n.t('experiments.toolbar.new_button'),
        type: 'emit',
        path: this.createUrl,
        buttonStyle: 'btn btn-primary',
      });

      return {
        left,
        right: [],
      };
    },
    filters() {
      const filters = [
        {
          key: 'query',
          type: 'Text',
        },
        {
          key: 'created_at',
          type: 'DateRange',
          label: this.i18n.t('filters_modal.created_on.label'),
        },
      ];

      return filters;
    },
  },
  methods: {
    updateTable() {
      this.editModalObject = null;
      this.moveModalObject = null;
      this.duplicateModalObject = null;
      this.descriptionModalObject = null;
      this.reloadingTable = true;
    },
    async archive(event, rows) {
      const ok = await this.$refs.archiveModal.show();
      if (ok) {
        axios.post(event.path, { experiment_ids: rows.map((row) => row.id) }).then((response) => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
    restore(event, rows) {
      axios.post(event.path, { experiment_ids: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
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
    move(_e, experiment) {
      [this.moveModalObject] = experiment;
    },
    edit(_e, experiment) {
      [this.editModalObject] = experiment;
    },
  },
};
</script>
