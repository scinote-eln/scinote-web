/* global GLOBAL_CONSTANTS */

import axios from '../../../../../packs/custom_axios.js';
import { satisfies } from 'compare-versions';
import editLaunchingApplicationModal from '../../modal/edit_launching_application_modal.vue';
import NoPredefinedAppModal from '../../modal/no_predefined_app_modal.vue';
import RestrictedExtensionModal from '../../modal/restricted_extension_modal.vue';
import UpdateVersionModal from '../../modal/update_version_modal.vue';

export default {
  data() {
    return {
      localAppName: null,
      scinoteEditRunning: null,
      showNoPredefinedAppModal: false,
      showRestrictedExtensionModal: false,
      showUpdateVersionModal: false,
      editAppModal: false,
      pollingInterval: null
    };
  },
  components: {
    editLaunchingApplicationModal,
    NoPredefinedAppModal,
    UpdateVersionModal,
    RestrictedExtensionModal
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
    async checkScinoteEditRunning() {
      // responses will be cached on window, so the requests only run once per page load
      if (window.scinoteEditRunning !== undefined) {
        this.scinoteEditRunning = window.scinoteEditRunning;
        return;
      }

      if (this.attributes.urls.open_locally_api === undefined) return;

      try {
        const statusResponse = await axios.get(
          `${this.attributes.urls.open_locally_api}/status`
        );

        if (statusResponse.status === 200) {
          window.scinoteEditRunning = true;
          window.scinoteEditVersion = statusResponse.data.version;
        } else {
          window.scinoteEditRunning = false;
        }
      } catch (error) {
        window.scinoteEditRunning = false;
      }

      this.scinoteEditRunning = window.scinoteEditRunning;
    },
    async fetchLocalAppInfo() {
      this.checkScinoteEditRunning();

      if (this.attributes.urls.open_locally_api === undefined) return;

      // responses will be cached on window, so the requests only run once per page load
      if (window.scinoteEditRunning === false) return;

      if (window.scinoteEditLocalApps === undefined) {
        window.scinoteEditLocalApps = {};
      }

      if (window.scinoteEditLocalApps[this.attributes.file_extension] !== undefined) {
        this.localAppName = window.scinoteEditLocalApps[this.attributes.file_extension];
        return;
      }

      try {
        const response = await axios.get(
          `${this.attributes.urls.open_locally_api}/default-application/${this.attributes.file_extension}`
        );

        if (response.data.application.toLowerCase() !== 'pick an app') {
          window.scinoteEditLocalApps[this.attributes.file_extension] = response.data.application;
          this.localAppName = response.data.application;
        }
      } catch (error) {
        if (error.response?.status === 404) {
          window.scinoteEditLocalApps[this.attributes.file_extension] = null;
          return; // all good, no app was found for the file
        }

        console.error('Error in request: ', error);
      }
    },
    async openLocally() {
      const restrictedExtension = GLOBAL_CONSTANTS.SCINOTE_EDIT_RESTRICTED_EXTENSIONS.includes(
        this.attributes.file_extension.toUpperCase()
      );

      if (this.isWrongVersion(window.scinoteEditVersion)) {
        this.showUpdateVersionModal = true;
        return;
      } else if (restrictedExtension) {
        this.showRestrictedExtensionModal = true;
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

