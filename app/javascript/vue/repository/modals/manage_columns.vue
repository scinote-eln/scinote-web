<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content" data-e2e="e2e-MD-manageColumns">
        <ColumnsList
          v-if="view === 'list'"
          :columnDefs="columnDefs"
          :tableState="tableState"
          :canManageColumns="canManageColumns"
          @hideColumn="(column) => $emit('hideColumn', column)"
          @showColumn="(column) => $emit('showColumn', column)"
          @unPinColumn="(column) => $emit('unPinColumn', column)"
          @pinColumn="(column) => $emit('pinColumn', column)"
          @reorderColumns="(columns) => $emit('reorderColumns', columns)"
          @resetToDefault="onResetToDefault"
          @add="openForm(null)"
          @edit="openForm"
          @delete="confirmDelete"
        />
        <ColumnForm
          v-else
          :column="editingColumn"
          :repositoryId="repositoryId"
          :columnDefs="columnDefs"
          @back="view = 'list'"
          @saved="onSaved"
        />
      </div>
    </div>
    <teleport to="body">
      <ConfirmationModal
        :title="i18n.t('repositories.modal_delete_column.title')"
        :description="deleteDescription"
        confirmClass="btn btn-danger"
        :confirmText="i18n.t('repositories.modal_delete_column.delete')"
        ref="deleteConfirm"
      ></ConfirmationModal>
    </teleport>
  </div>
</template>

<script>
/* global HelperModule */
import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios.js';
import { repository_repository_column_path } from '../../../routes.js';
import ColumnsList from './manage_columns/columns_list.vue';
import ColumnForm from './manage_columns/column_form.vue';
import ConfirmationModal from '../../shared/confirmation_modal.vue';

export default {
  name: 'NewModal',
  props: {
    columnDefs: { type: Array, required: true },
    tableState: { type: Object },
    repositoryId: { type: [String, Number] },
    canManageColumns: { type: Boolean, default: false }
  },
  components: {
    ColumnsList,
    ColumnForm,
    ConfirmationModal
  },
  mixins: [modalMixin],
  data() {
    return {
      view: 'list',
      editingColumn: null,
      deleteDescription: ''
    };
  },
  methods: {
    openForm(column) {
      this.editingColumn = column;
      this.view = 'form';
    },
    onSaved(message) {
      if (message) HelperModule.flashAlertMsg(message, 'success');
      this.view = 'list';
      this.editingColumn = null;
      this.$emit('reloadColumns');
    },
    onResetToDefault() {
      this.$emit('resetToDefault');
      this.close();
    },
    async confirmDelete(column) {
      this.deleteDescription = `<p>${this.i18n.t('repositories.modal_delete_column.message', { column: column.headerName })}</p>`;
      const ok = await this.$refs.deleteConfirm.show();
      if (!ok) return;

      axios.delete(repository_repository_column_path(this.repositoryId, column.cellRendererParams.columnId))
        .then((response) => {
          HelperModule.flashAlertMsg(response.data.message, 'success');
          this.$emit('reloadColumns');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
        });
    }
  }
};
</script>
