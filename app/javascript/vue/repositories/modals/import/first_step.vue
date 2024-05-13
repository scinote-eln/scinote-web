<template>
  <div ref="firstStep" class="flex flex-col gap-6 h-full">

    <!-- body -->
    <div class="flex flex-col gap-6 h-full w-full">

      <!-- export -->
      <div id="export-section" class="flex flex-col gap-3">
        <h3 class="my-0 text-sn-dark-grey">
          {{ i18n.t('repositories.import_records.steps.step1.importTitle') }}
        </h3>
        <div id="export-buttons" class="flex flex-row gap-4">
          <button class="btn btn-secondary btn-sm" @click="exportFullInventory">
            <i class="sn-icon sn-icon-export"></i>
            {{ i18n.t('repositories.import_records.steps.step1.exportFullInvBtnText') }}
          </button>
          <button class="btn btn-secondary btn-sm">
            <i class="sn-icon sn-icon-export"></i>
            {{ i18n.t('repositories.import_records.steps.step1.exportEmptyInvBtnText') }}
          </button>
        </div>
      </div>

      <!-- import -->
      <div id="import-section" class="flex flex-col gap-3 h-full w-full">
        <h3 class="my-0 text-sn-dark-grey">
          {{ i18n.t('repositories.import_records.steps.step1.importBtnText') }}
        </h3>
        <DragAndDropUpload
          @file:dropped="uploadFile"
          @file:error="handleError"
          @file:error:clear="this.error = null"
          :supportingText="`${i18n.t('repositories.import_records.steps.step1.dragAndDropSupportingText')}`"
          :supportedFormats="['xlsx', 'csv', 'xls', 'txt', 'tsv']"
        />
      </div>
    </div>

    <!-- divider -->
    <div class="sci-divider"></div>

    <!-- footer -->
    <div class="flex justify-end">
      <div v-if="error" class="flex flex-row gap-2 my-auto mr-auto text-sn-delete-red">
        <i class="sn-icon sn-icon-alert-warning"></i>
        <div class="my-auto">{{ error }}</div>
      </div>
      <div v-if="exportInventoryMessage" class="flex flex-row gap-2 my-auto mr-auto text-sn-alert-green">
        <i class="sn-icon sn-icon-check"></i>
        <div class="my-auto">{{ exportInventoryMessage }}</div>
      </div>
      <button class="btn btn-secondary" data-dismiss="modal" aria-label="Close">
        {{ i18n.t('repositories.import_records.steps.step1.cancelBtnText') }}
      </button>
    </div>
  </div>
</template>

<script>
import axios from '../../../../packs/custom_axios';
import DragAndDropUpload from '../../../shared/drag_and_drop_upload.vue';

export default {
  name: 'FirstStep',
  emits: ['step:next', 'info:hide'],
  components: {
    DragAndDropUpload
  },
  props: {
    stepProps: {
      type: Object,
      required: false
    }
  },
  data() {
    return {
      showingInfo: false,
      error: null,
      teamId: null,
      parseSheetUrl: null,
      exportInventoryMessage: null
    };
  },
  async created() {
    // Fetch repository data and set it to state
    const repositoryData = await this.fetchSerializedRepositoryData();
    this.teamId = String(repositoryData.data.attributes.team_id);
    this.parseSheetUrl = repositoryData.data.attributes.urls.parse_sheet;
  },
  watch: {
    // clearing export message
    exportInventoryMessage(newVal, oldVal) {
      if (newVal && newVal !== oldVal) {
        setTimeout(() => {
          this.exportInventoryMessage = null;
        }, 3000);
      }
    }
  },
  methods: {
    async fetchSerializedRepositoryData() {
      const url = window.location.pathname;
      try {
        const response = await axios.get(url);
        return response.data;
      } catch (error) {
        console.error(error);
      }
      return '';
    },
    async exportFullInventory() {
      const exportFullInventoryUrl = `/teams/${this.teamId}/export_repositories`;
      const formData = new FormData();
      const repositoryIds = [this.teamId];
      const fileType = 'csv';

      // required payload
      formData.append('repository_ids', repositoryIds);
      formData.append('file_type', fileType);

      try {
        const response = await axios.post(exportFullInventoryUrl, formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });

        if (!response.status === 200) {
          throw new Error('Network response was not ok');
        }

        if (response.status === 200) {
          this.exportInventoryMessage = response.data.message;
        }
        return response;
      } catch (error) {
        console.error(error);
      }
      return '';
    },
    async uploadFile(file) {
      this.uploading = true;

      // First, parse the sheet
      const parsedSheetResponse = await this.parseSheet(file);

      // If parsed successfully, go to next step and pass through the necessary data
      if (parsedSheetResponse) {
        const {
          header: columnNames,
          available_fields: availableFields,
          columns: exampleData
        } = parsedSheetResponse.data.import_data;
        const fileName = file.name;
        const tempFile = parsedSheetResponse.data.temp_file;

        this.$emit('step:next', {
          columnNames,
          availableFields,
          exampleData,
          fileName,
          tempFile
        });
      }
    },
    async parseSheet(file) {
      const formData = new FormData();

      // required payload
      formData.append('file', file);
      formData.append('team_id', this.teamId);

      try {
        const response = await axios.post(this.parseSheetUrl, formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });

        if (!response.status === 200) {
          throw new Error('Network response was not ok');
        }
        return response;
      } catch (error) {
        console.error(error);
      }
      return '';
    },
    handleError(error) {
      this.error = error;
    }
  }
};
</script>
