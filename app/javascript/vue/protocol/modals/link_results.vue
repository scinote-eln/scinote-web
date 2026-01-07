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
              {{ i18n.t('protocols.steps.modals.link_results.title') }}
            </h4>
          </div>
          <div v-if="loading" class="modal-body h-40 flex items-center justify-center">
            <div class="sci-loader"></div>
          </div>
          <div v-else-if="results.length > 0" class="modal-body">
            <p>
              {{ i18n.t('protocols.steps.modals.link_results.description') }}
            </p>
            <div class="mt-6">
              <label class="sci-label">{{ i18n.t('protocols.steps.modals.link_results.result_label') }}</label>
              <SelectDropdown
                :options="results"
                :value="selectedResults"
                :searchable="true"
                @change="changeResults"
                :multiple="true"
                :withCheckboxes="true"
                :placeholder="i18n.t('protocols.steps.modals.link_results.placeholder')" />
            </div>
          </div>
          <div v-else class="modal-body">
            <p>
              {{ i18n.t('protocols.steps.modals.link_results.empty_description') }}
            </p>
          </div>
          <div v-if="!loading" class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">
              {{ i18n.t('general.cancel') }}
            </button>
            <template v-if="results.length > 0">
              <button v-if="step.attributes.results.length == 0" type="submit" :disabled="isSameData" class="btn btn-primary" @click="linkResults">
                {{ i18n.t('protocols.steps.modals.link_results.link_results') }}
              </button>
              <button v-else type="submit" :disabled="isSameData" class="btn btn-primary" @click="linkResults">
                {{ i18n.t('general.save') }}
              </button>
            </template>
            <template v-else>
              <a :href="resultsPageUrl" class="btn btn-primary">
                {{ i18n.t('protocols.steps.modals.link_results.go_to_results') }}
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
  list_my_module_results_path,
  list_protocol_result_templates_path,
  my_module_results_path,
  protocol_result_templates_path,
  link_results_step_results_path,
  link_results_step_result_templates_path
} from '../../../routes.js';

export default {
  name: 'LinksResultsModal',
  props: {
    step: {
      type: Object,
      required: true
    }
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown
  },
  created() {
    this.selectedResults = this.step.attributes.results.map((result) => result.id);
    this.initialResults = this.step.attributes.results.map((result) => result.id);
    this.loadResults();
  },
  data() {
    return {
      results: [],
      initialResults: [],
      selectedResults: [],
      loading: true
    };
  },
  computed: {
    resultsListUrl() {
      if (this.step.attributes.my_module_id) {
        return list_my_module_results_path({ my_module_id: this.step.attributes.my_module_id, with_linked_step_id: this.step.id });
      }
      return list_protocol_result_templates_path({ protocol_id: this.step.attributes.protocol_id, with_linked_step_id: this.step.id });
    },
    resultsPageUrl() {
      if (this.step.attributes.my_module_id) {
        return my_module_results_path({ my_module_id: this.step.attributes.my_module_id });
      }
      return protocol_result_templates_path({ protocol_id: this.step.attributes.protocol_id });
    },
    resultsLinkUrl() {
      if (this.step.attributes.my_module_id){
        return link_results_step_results_path({ format: 'json' });
      }
      return link_results_step_result_templates_path({ format: 'json' });
    },
    isSameData() {
      return this.selectedResults.length === this.initialResults.length &&
             this.selectedResults.every((value) => this.initialResults.includes(value));
    }
  },
  methods: {
    changeResults(value) {
      this.selectedResults = value;
    },
    linkResults() {
      axios.post(
        this.resultsLinkUrl,
        {
          step_ids: this.step.id,
          result_ids: this.selectedResults
        }
      )
        .then((response) => {
          this.$emit('close');
          this.$emit('updateStep', response.data.results);
          HelperModule.flashAlertMsg(I18n.t('protocols.steps.modals.link_results.success'), 'success');
        }).catch(() => {
          HelperModule.flashAlertMsg(I18n.t('protocols.steps.modals.link_results.error'), 'danger');
          this.$emit('close');
        });
    },
    loadResults() {
      axios.get(this.resultsListUrl)
        .then((response) => {
          this.results = response.data;
          this.loading = false;
        }).catch(() => {
          HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
          this.loading = false;
        });
    }
  }
};
</script>
