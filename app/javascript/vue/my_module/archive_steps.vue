<template>
  <div>
    <ArchiveToolbar
      :mode="'steps'"
      :sort="sort"
      :objects="steps"
      :objectsCollapsed="stepCollapsed"
      @setSort="setSort"
      @setFilters="setFilters"
      @expandAll="expandSteps"
      @collapseAll="collapseSteps"
      @update:mode="$emit('update:mode', $event)"
    />
    <div class="steps-wrapper">
      <div
        :class="{ 'tw-hidden': loadingOverlay }"
        class="steps-list">
        <Step v-for="step in steps" :key="step.id"
          ref="steps"
          :step="step"
          :protocolId="protocolId"
          @step:deleted="removeStep"
          @step:restored="removeStep"
          @step:collapsed="checkStepsState"
          @step:empty="removeStep"
        />
        <div v-if="!loadingOverlay && steps.length === 0" class="px-4 py-6 bg-white my-4 text-gray-500">
          {{ i18n.t('protocols.steps.no_steps_placeholder') }}
        </div>
      </div>
      <div v-if="loadingOverlay" class="text-center h-20 flex items-center justify-center">
        <div class="sci-loader"></div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import Step from '../protocol/archived_step.vue';
import StepCollapseState from '../protocol/mixins/step_collapse_state.js';
import ArchiveToolbar from './archive_toolbar.vue';

import {
  steps_path,
} from '../../routes.js';

export default {
  name: 'ArchiveSteps',
  props: {
    protocolId: {
      required: true
    },
  },
  mixins: [StepCollapseState],
  data() {
    return {
      steps: [],
      sort: null,
      filters: {},
      nextPageUrl: null,
      loadingOverlay: false
    };
  },
  components: {
    Step,
    ArchiveToolbar
  },
  created() {
    this.loadingOverlay = true;
  },
  computed: {
    stepsUrl() {
      return steps_path({ protocol_id: this.protocolId, view_mode: 'archived' });
    }
  },
  mounted() {
    this.loadSteps();
  },
  methods: {
    loadSteps() {
      if (this.loadingOverlay) {
        const params = this.sort ? { ...this.filters, sort: this.sort } : { ...this.filters };
        params['format'] = 'json';
        axios.get(this.stepsUrl, { params }).then((response) => {
          let result = response.data
          this.steps = result.data;
          this.steps.forEach((step) => {
            step.attachments = [];
            step.relationships.assets.data.forEach((asset) => {
              step.attachments.push(result.included.find((a) => a.id === asset.id && a.type === 'assets'));
            });

            step.elements = [];
            step.relationships.step_orderable_elements.data.forEach((element) => {
              step.elements.push(result.included.find((e) => e.id === element.id && e.type === 'step_orderable_elements'));
            });
          });
          this.sort = response.data.meta.sort;
          this.loadingOverlay = false;

          this.$nextTick(() => {
            this.checkStepsState();
          });
        });
      }
    },
    setSort(sort) {
      this.sort = sort;
      this.loadingOverlay = true;
      this.loadSteps();
    },
    setFilters(filters) {
      this.filters = filters;
      this.loadingOverlay = true;
      this.loadSteps();
    },
    removeStep(step_id) {
      this.steps = this.steps.filter((r) => r.id != step_id);
    },
  }
};
</script>
