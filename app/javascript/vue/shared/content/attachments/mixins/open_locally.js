import axios from '../../../../../packs/custom_axios.js';
import { satisfies } from 'compare-versions';

export default {
  data() {
    return {
      localAppName: null,
      scinoteEditRunning: false,
      scinoteEditVersion: null      
    };
  },
  computed: {
    canOpenLocally() {
      return this.scinoteEditRunning &&
        !!this.attachment.attributes.urls.open_locally &&
        this.attachment.attributes.asset_type !== 'gene_sequence' &&
        this.attachment.attributes.asset_type !== 'marvinjs'
    }
  },
  methods: {
    async fetchLocalAppInfo() {
      try {
        const statusResponse = await axios.get(
          `${this.attachment.attributes.urls.open_locally_api}/status`
        );

        if (statusResponse.status === 200) {
          this.scinoteEditRunning = true;
          this.scinoteEditVersion = statusResponse.data.version;
        } else {
          return;
        }

        const response = await axios.get(
          `${this.attachment.attributes.urls.open_locally_api}/default-application/${this.attachment.attributes.file_extension}`
        );

        if (response.data.application.toLowerCase() !== 'pick an app') {
          this.localAppName = response.data.application;
        }
      } catch (error) {
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
        const { data } = await axios.get(this.attachment.attributes.urls.open_locally);
        await axios.post(this.attachment.attributes.urls.open_locally_api + '/download', data);
      } catch (error) {
        console.error('Error in request:', error);
      }
    },
    isWrongVersion(version) {
      const min = GLOBAL_CONSTANTS.MIN_SCINOTE_EDIT_VERSION;
      const max = GLOBAL_CONSTANTS.MAX_SCINOTE_EDIT_VERSION;
      version = "3.0"
      return !satisfies(version, `${min} - ${max}`);
    }
  }
}

