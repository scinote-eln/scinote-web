<template>
  <div class="flex flex-col gap-4">
    <h2 class="text-xl font-semibold m-0">{{ i18n.t('protocols.report_template.data_inputs.title') }}</h2>
    <div class="w-full sci-toast sci-toast-info">
      {{ i18n.t('protocols.report_template.data_inputs.banner') }}
    </div>
    <div v-for="inputTag in inputTags" :key="inputTag.label" class="bg-sn-super-light-grey p-4 rounded text-base">
      <div class="flex flex-col gap-2">
        <div class="flex justify-between items-center">
          <div class="font-semibold leading-6">
            {{ inputTag.label }}
          </div> 
          <div v-if="inputTag.tag" class="flex items-center gap-1">
            {{ inputTag.tag }}
            <button class="btn btn-light btn-xs icon-btn btn-black" @click="copy(inputTag.tag)">
              <i class="sn-icon sn-icon-copyclipboard"></i>
            </button>
          </div>
        </div>
        <div v-for="inputs in inputTag.inputs" class="flex pl-6 justify-between items-center">
          <div>
            <i v-if="inputs.icon" class="sn-icon" :class="inputs.icon"></i>
            {{ inputs.label }}
          </div> 
          <div class="flex items-center gap-1">
            {{ inputs.tag }}
            <button class="btn btn-light btn-xs icon-btn btn-black" @click="copy(inputs.tag)">
              <i class="sn-icon sn-icon-copyclipboard"></i>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../../packs/custom_axios.js';
import {
  input_tags_protocol_protocol_report_templates_path
} from '../../../routes.js';

export default {
  name: 'ProtocolReportTemplateDataInputs',
  props: {
    protocolId: {
      required: true
    }
  },
  data() {
    return {
      inputTags: []
    }
  },
  created() {
    this.loadDataInputs();
  },
  computed: {
    url() {
      return input_tags_protocol_protocol_report_templates_path(this.protocolId);
    }
  },
  methods: {
    loadDataInputs() {
      axios.get(this.url).then((response) => {
        this.inputTags = response.data;
      });

    },
    copy(value) {
      navigator.clipboard.writeText(value).then(
        () => {}
      );
    },
  }
};
</script>
