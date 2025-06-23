<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block">
              {{ i18n.t('my_modules.results.modals.link_steps.title') }}
            </h4>
          </div>
          <div v-if="steps.length > 0" class="modal-body">
            <p>
              {{ i18n.t('my_modules.results.modals.link_steps.description') }}
            </p>
            <div class="mt-6">
              <label class="sci-label">{{ i18n.t('my_modules.results.modals.link_steps.steps_label') }}</label>
              <SelectDropdown
                :options="steps"
                :value="selectedSteps"
                :searchable="true"
                @change="changeSteps"
                :multiple="true"
                :withCheckboxes="true"
                :placeholder="i18n.t('my_modules.results.modals.link_steps.placeholder')" />
            </div>
          </div>
          <div v-else class="modal-body">
            <p>
              {{ i18n.t('my_modules.results.modals.link_steps.empty_description') }}
            </p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">
              {{ i18n.t('general.cancel') }}
            </button>
            <template v-if="steps.length > 0">
              <button v-if="result.attributes.steps.length == 0" type="submit" :disabled="isSameData" class="btn btn-primary" @click="linkSteps">
                {{ i18n.t('my_modules.results.modals.link_steps.link_steps') }}
              </button>
              <button v-else type="submit" class="btn btn-primary" :disabled="isSameData" @click="linkSteps">
                {{ i18n.t('general.save') }}
              </button>
            </template>
            <template v-else>
              <a :href="protocolPageUrl" class="btn btn-primary">
                {{ i18n.t('my_modules.results.modals.link_steps.go_to_protocol') }}
              </a>
            </template>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule I18n */

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin.js';
import {
  list_steps_path,
  protocols_my_module_path,
  link_steps_step_results_path
} from '../../../routes.js';

export default {
  name: 'LinkStepsModal',
  props: {
    result: {
      type: Object,
      required: true
    },
    protocolId: {
      type: Number,
      required: true
    }
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown
  },
  created() {
    this.selectedSteps = this.result.attributes.steps.map((step) =>  step.id);
    this.initialSteps = this.result.attributes.steps.map((step) => step.id);
    this.loadSteps();
  },
  data() {
    return {
      steps: [],
      selectedSteps: [],
      initialSteps: []
    };
  },
  computed: {
    stepsListUrl() {
      return list_steps_path({ protocol_id: this.protocolId });
    },
    protocolPageUrl() {
      return protocols_my_module_path({ id: this.result.attributes.my_module_id });
    },
    stepsLinkUrl() {
      return link_steps_step_results_path({ format: 'json' });
    },
    isSameData() {
      return this.selectedSteps.length === this.initialSteps.length &&
             this.selectedSteps.every((value) => this.initialSteps.includes(value));
    }
  },
  methods: {
    changeSteps(value) {
      this.selectedSteps = value;
    },
    linkSteps() {
      axios.post(
        this.stepsLinkUrl,
        {
          step_ids: this.selectedSteps,
          result_ids: this.result.id
        }
      )
        .then((response) => {
          this.$emit('close');
          this.$emit('updateResult', response.data.steps);
          HelperModule.flashAlertMsg(I18n.t('protocols.steps.modals.link_results.success'), 'success');
        }).catch(() => {
          HelperModule.flashAlertMsg(I18n.t('protocols.steps.modals.link_results.error'), 'danger');
          this.$emit('close');
        });
    },
    loadSteps() {
      axios.get(this.stepsListUrl)
        .then((response) => {
          this.steps = response.data;
        });
    }
  }
};
</script>
