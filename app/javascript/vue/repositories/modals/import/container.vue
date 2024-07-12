<template>
  <div v-if="modalOpened" class="relative">
    <component
      v-if="activeStep !== 'ExportModal'"
      :is="activeStep"
      :params="params"
      :key="modalId"
      :loading="loading"
      @uploadFile="uploadFile"
      @generatePreview="generatePreview"
      @changeStep="changeStep"
      @importRows="importRecords"
      @updateAutoMapping="updateAutoMapping"
    />
    <ExportModal
      v-else
      :rows="[{id: params.id, team: params.attributes.team_name}]"
      :exportAction="params.attributes.export_actions"
      @close="activeStep ='UploadStep'"
      @export="activeStep = 'UploadStep'"
    />
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../../../packs/custom_axios';
import InfoModal from '../../../shared/info_modal.vue';
import UploadStep from './upload_step.vue';
import MappingStep from './mapping_step.vue';
import PreviewStep from './preview_step.vue';
import ExportModal from '../export.vue';

export default {
  name: 'ImportRepositoryModal',
  components: {
    InfoModal,
    UploadStep,
    MappingStep,
    PreviewStep,
    ExportModal
  },
  props: {
    repositoryUrl: String,
    required: true
  },
  data() {
    return {
      modalOpened: false,
      activeStep: 'UploadStep',
      params: { autoMapping: true },
      modalId: null,
      loading: false
    };
  },
  created() {
    window.importRepositoryModalComponent = this;
  },
  methods: {
    open() {
      this.activeStep = 'UploadStep';
      this.params.selectedItems = null;
      this.params.autoMapping = true;
      this.fetchRepository();
    },
    fetchRepository() {
      axios.get(this.repositoryUrl)
        .then((response) => {
          this.params = { ...this.params, ...response.data.data };
          this.modalId = Math.random().toString(36);
          this.modalOpened = true;
        });
    },
    uploadFile(params) {
      this.params = { ...this.params, ...params };
      this.activeStep = 'MappingStep';
    },
    updateAutoMapping(value) {
      this.params.autoMapping = value;
    },
    generatePreview(selectedItems, updateWithEmptyCells, onlyAddNewItems) {
      this.params.selectedItems = selectedItems;
      this.params.updateWithEmptyCells = updateWithEmptyCells;
      this.params.onlyAddNewItems = onlyAddNewItems;
      this.importRecords(true);
    },
    changeStep(step) {
      this.activeStep = step;
    },
    generateMapping() {
      return this.params.selectedItems.reduce((obj, item) => {
        obj[item.index] = item.key || '';
        return obj;
      }, {});
    },
    importRecords(preview) {
      if (this.loading) {
        return;
      }

      const jsonData = {
        file_id: this.params.temp_file.id,
        mappings: this.generateMapping(),
        id: this.params.id,
        preview: preview,
        should_overwrite_with_empty_cells: this.params.updateWithEmptyCells,
        can_edit_existing_items: !this.params.onlyAddNewItems
      };

      this.loading = true;

      axios.post(this.params.attributes.urls.import_records, jsonData)
        .then((response) => {
          if (preview) {
            this.params.preview = response.data.changes;
            this.params.import_date = response.data.import_date;
            this.activeStep = 'PreviewStep';
          } else {
            HelperModule.flashAlertMsg(response.data.message, 'success');
            this.modalOpened = false;
            this.activeStep = null;
            $('.dataTable.repository-dataTable').DataTable().ajax.reload(null, false);
          }

          this.loading = false;
        })
        .catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.message, 'danger');
          this.loading = false;
        });
    }
  }
};
</script>
