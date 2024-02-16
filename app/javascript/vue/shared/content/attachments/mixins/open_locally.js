import axios from '../../../../../packs/custom_axios.js';
import { satisfies } from 'compare-versions';
import editLaunchingApplicationModal from '../../modal/edit_launching_application_modal.vue';
import NoPredefinedAppModal from '../../modal/no_predefined_app_modal.vue';
import UpdateVersionModal from '../../modal/update_version_modal.vue';

export default {
  data() {
    return {
      localAppName: null,
      scinoteEditRunning: false,
      scinoteEditVersion: null,
      showNoPredefinedAppModal: false,
      showUpdateVersionModal: false,
      editAppModal: false,
      pollingInterval: null,
    };
  },
  components: {
    editLaunchingApplicationModal,
    NoPredefinedAppModal,
    UpdateVersionModal
  },
  computed: {
    attributes() {
      return this.attachment.attributes;
    },
    canOpenLocally() {
      return this.scinoteEditRunning
             && !!this.attributes.urls.open_locally
             && this.attributes.asset_type !== 'gene_sequence'
             && this.attributes.asset_type !== 'marvinjs';
    }
  },
  beforeUnmount() {
    this.stopPolling();
  },
  methods: {
    async fetchLocalAppInfo() {
      try {
        const statusResponse = await axios.get(
          `${this.attributes.urls.open_locally_api}/status`
        );

        if (statusResponse.status === 200) {
          this.scinoteEditRunning = true;
          this.scinoteEditVersion = statusResponse.data.version;
        } else {
          return;
        }

        const response = await axios.get(
          `${this.attributes.urls.open_locally_api}/default-application/${this.attributes.file_extension}`
        );

        if (response.data.application.toLowerCase() !== 'pick an app') {
          this.localAppName = response.data.application;
        }
      } catch (error) {
        if (error.response?.status === 404) return; // all good, no app was found for the file

        console.error('Error in request: ', error);
      }
    },
    async openLocally() {
      if (this.isWrongVersion(this.scinoteEditVersion)) {
        this.showUpdateVersionModal = true;
        return;
      } else if (this.localAppName === null) {
        this.showNoPredefinedAppModal = true;
        return;
      }

      this.editAppModal = true;
      try {
        this.startPolling();
        const { data } = await axios.get(this.attributes.urls.open_locally);
        await axios.post(`${this.attributes.urls.open_locally_api}/download`, data);
      } catch (error) {
        console.error('Error in request:', error);
      }
    },
    isWrongVersion(version) {
      const { min, max } = this.attributes.edit_version_range;
      return !satisfies(version, `${min} - ${max}`);
    },
    async pollForChanges() {
      try {
        const checksumResponse = await axios.get(this.attributes.urls.asset_checksum);

        if (checksumResponse.status === 200) {
          const currentChecksum = checksumResponse.data.checksum;

          if (currentChecksum !== this.attributes.checksum) {
            this.$emit('attachment:changed', this.attachment.id);
          }
        }
      } catch (error) {
        console.error('Error polling for changes:', error);
      }
    },
    startPolling() {
      if (this.pollingInterval === null) {
        this.pollingInterval = setInterval(this.pollForChanges, GLOBAL_CONSTANTS.ASSET_POLLING_INTERVAL);
      }
    },
    stopPolling() {
      if (this.pollingInterval !== null) {
        clearInterval(this.pollingInterval);
        this.pollingInterval = null;
      }
    }
  }
}

