import axios from '../../../../../packs/custom_axios.js';

export default {
  data() {
    return {
      localAppName: null,
      scinoteEditRunning: false
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
      if (this.localAppName === null) {
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
    }
  }
}

