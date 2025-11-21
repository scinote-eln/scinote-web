<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" data-e2e="e2e-MD-protocol-addProtocolSteps">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button
              type="button"
              class="close"
              data-dismiss="modal"
              aria-label="Close"
              data-e2e="e2e-BT-protocol-addProtocolStepsModal-close"
            >
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" data-e2e="e2e-TX-protocol-addProtocolStepsModal-title">
              {{ i18n.t('protocols.steps.modals.add_protocol_steps.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <p class="mb-6" data-e2e="e2e-TX-protocol-addProtocolStepsModal-description">
              {{ i18n.t('protocols.steps.modals.add_protocol_steps.description')}}
            </p>
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t('protocols.steps.modals.add_protocol_steps.protocol_label') }}</label>
              <SelectDropdown
                :placeholder="i18n.t('protocols.steps.modals.add_protocol_steps.protocol_placeholder')"
                :optionsUrl="protocolsUrl"
                :searchable="true"
                :value="selectedProtocol"
                @change="selectedProtocol = $event"
                :e2eValue="'e2e-DD-protocol-addProtocolStepsModal-selectProtocol'"
              ></SelectDropdown>
            </div>
            <div class="relative">
              <label class="sci-label">{{ i18n.t('protocols.steps.modals.add_protocol_steps.protocol_steps_label') }}</label>
              <SelectDropdown
                :key="selectedProtocol"
                :disabled="!selectedProtocol"
                :optionsUrl="protocolStepsUrl"
                :urlParams="{ selected_protocol_id: selectedProtocol }"
                :placeholder="i18n.t('protocols.steps.modals.add_protocol_steps.protocol_steps_placeholder')"
                :multiple="true"
                :withCheckboxes="true"
                :searchable="true"
                :value="selectedSteps"
                @change="selectedSteps= $event"
                :e2eValue="'e2e-DD-protocol-addProtocolStepsModal-selectSteps'"
              ></SelectDropdown>
            </div>
          </div>
          <div class="modal-footer">
            <button
              type="button"
              class="btn btn-secondary"
              data-dismiss="modal"
              data-e2e="e2e-BT-protocol-addProtocolStepsModal-cancel"
            >
              {{ i18n.t('general.cancel') }}
            </button>
            <button
              class="btn btn-primary"
              :disabled="submitting || !validObject"
              type="submit"
              data-e2e="e2e-BT-protocol-addProtocolStepsModal-addSteps"
            >
              {{ i18n.t('protocols.steps.modals.add_protocol_steps.confirm') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

/* global HelperModule */
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin.js';
import SelectDropdown from '../../shared/select_dropdown.vue';
import {
  list_published_protocol_templates_protocol_path,
  list_protocol_steps_protocol_steps_path
} from '../../../routes.js';

export default {
  name: 'AddStepsModal',
  props: {
    protocol: Object
  },
  components: {
    SelectDropdown
  },
  mixins: [modalMixin],
  data() {
    return {
      selectedProtocol: null,
      selectedRow: null,
      submitting: false,
      selectedSteps: null
    };
  },
  watch: {
    selectedProtocol() {
      this.selectedSteps = null;
    }
  },
  computed: {
    validObject() {
      return this.selectedProtocol && this.selectedSteps?.length;
    },
    protocolsUrl() {
      return list_published_protocol_templates_protocol_path(this.protocol.id);
    },
    protocolStepsUrl() {
      if (!this.selectedProtocol) {
        return null;
      }

      return list_protocol_steps_protocol_steps_path(this.selectedProtocol);
    }
  },
  mounted() {
    // move modal to body to avoid z-index issues
    $('body').append($(this.$refs.modal));
  },
  methods: {
    submit() {
      this.submitting = true;
      axios.post(this.protocol.attributes.urls.add_protocol_steps_url, {
        selected_protocol: this.selectedProtocol,
        steps: this.selectedSteps
      }).then((response) => {
        this.submitting = false;
        const steps = response.data.data;
        steps.forEach((step) => {
          step.attachments = [];
          step.elements = [];
          response.data.included.forEach((included) => {
            if (included.type === 'assets') {
              step.attachments.push(included);
            } else if (included.type === 'step_orderable_elements') {
              step.elements.push(included);
            }
          });
        });
        this.$emit('confirm', steps);
        this.close();
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.modals.add_protocol_steps.success_flash', { count: steps.length }), 'success');
      }).catch(() => {
        this.submitting = false;
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.modals.add_protocol_steps.error_flash'), 'danger');
      });
    }
  }
};
</script>
