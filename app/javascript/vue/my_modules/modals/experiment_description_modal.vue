<template>
  <a class="btn btn-light"
     data-e2e="e2e-BT-topToolbar-showExperimentDescription"
     @click="showExperimentDescription = true">
    <i class="sn-icon sn-icon-info"></i>
    <span class="tw-hidden lg:inline">{{ i18n.t('experiments.toolbar.description_button') }}</span>
  </a>
  <div class="flex">
    <ExperimentDescriptionModal
      v-if="experiment && showExperimentDescription"
      :object="experiment.attributes"
      @update="updateExperimentDescription"
      @close="showExperimentDescription = false"/>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../../packs/custom_axios.js';
import ExperimentDescriptionModal from '../../shared/datatable/modals/description.vue';

export default {
  name: 'MyModulesList',
  components: {
    ExperimentDescriptionModal
  },
  props: {
    experimentUrl: { type: String, required: true }
  },
  data() {
    return {
      showExperimentDescription: false,
      experiment: null
    };
  },
  created() {
    this.loadExperiment();
  },
  mounted() {
  },
  computed: {
  },
  methods: {
    loadExperiment() {
      axios.get(this.experimentUrl).then((response) => {
        this.experiment = response.data.data;
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    updateExperimentDescription(description) {
      axios.put(this.experiment.attributes.urls.update, {
        experiment: {
          description
        }
      }).then(() => {
        this.loadExperiment();
      });
    }
  }
};
</script>
