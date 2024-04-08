<template>
  <infoModal ref="modal" :startHidden="true" :infoParams="{}" :title="'UPDATE'" :helpText="'HELP ME'">
    UPDAE
  </infoModal>
</template>

<script>
/* global HelperModule */

import axios from '../../../packs/custom_axios.js';
import InfoModal from '../../shared/info_modal.vue';

export default {
  name: 'ImportRepositoryModal',
  components: {InfoModal},
  props: {
    repositoryUrl: String, required: true
  },
  data() {
    return {
      infoParams: {}
    };
  },
  created() {
    window.importRepositoryModalComponent = this;
  },
  mounted() {
  },
  methods: {
    open() {
      this.$refs.modal.open();
    }
  }
};
</script>
