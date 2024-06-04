<template>
  <div v-if="modalOpened">
  <component
    v-if="activeStep !== 'ExportModal'"
    :is="activeStep"
    :params="params"
    :uploading="uploading"
    @uploadFile="uploadFile"
    @generatePreview="generatePreview"
    @changeStep="changeStep"
    @importRows="importRecords"
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

import axios from '../../../../packs/custom_axios';
import InfoModal from '../../../shared/info_modal.vue';
import UploadStep from './upload_step.vue';
import MappingStep from './mapping_step.vue';
import PreviewStep from './preview_step.vue';
import SuccessStep from './success_step.vue';
import ExportModal from '../export.vue';

export default {
  name: 'ImportRepositoryModal',
  components: {
    InfoModal,
    UploadStep,
    MappingStep,
    PreviewStep,
    SuccessStep,
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
      uploading: false,
      params: {}
    };
  },
  created() {
    window.importRepositoryModalComponent = this;
  },
  methods: {
    open() {
      this.activeStep = 'UploadStep';
      this.fetchRepository();
    },
    fetchRepository() {
      axios.get(this.repositoryUrl)
        .then((response) => {
          this.params = response.data.data;
          this.modalOpened = true;
        });
    },
    uploadFile(file) {
      this.uploading = true;
      const formData = new FormData();

      // required payload
      formData.append('file', file);

      axios.post(this.params.attributes.urls.parse_sheet, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
        .then((response) => {
          this.params = { ...this.params, ...response.data, file_name: file.name };
          this.activeStep = 'MappingStep';
          this.uploading = false;
        });
    },

    generatePreview(mappings, updateWithEmptyCells, onlyAddNewItems) {
      this.params.mapping = mappings;
      this.params.updateWithEmptyCells = updateWithEmptyCells;
      this.params.onlyAddNewItems = onlyAddNewItems;
      this.importRecords(true);
    },
    changeStep(step) {
      this.activeStep = step;
    },
    importRecords(preview) {
      const jsonData = {
        file_id: this.params.temp_file.id,
        mappings: this.params.mapping,
        id: this.params.id,
        preview: preview,
        should_overwrite_with_empty_cells: this.params.updateWithEmptyCells,
        can_edit_existing_items: !this.params.onlyAddNewItems
      };
      axios.post(this.params.attributes.urls.import_records, jsonData)
        .then((response) => {
          if (preview) {
            this.params.preview = response.data.changes;
            this.params.import_date = response.data.import_date;
            this.activeStep = 'PreviewStep';
          } else {
            this.activeStep = 'SuccessStep';
          }
        });
    }
  }
};
</script>
