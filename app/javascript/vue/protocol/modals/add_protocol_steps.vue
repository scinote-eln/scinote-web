<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" >
              {{ i18n.t('protocols.steps.modals.add_protocol_steps.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <p class="mb-6">{{ i18n.t('protocols.steps.modals.add_protocol_steps.description')}}</p>
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t('protocols.steps.modals.add_protocol_steps.protocol_label') }}</label>
              <SelectDropdown
                :placeholder="i18n.t('protocols.steps.modals.add_protocol_steps.protocol_placeholder')"
                :optionsUrl="protocolsUrl"
                :searchable="true"
                :value="selectedProtocol"
                @change="selectedProtocol = $event"
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
              ></SelectDropdown>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="submitting || !validObject" type="submit">
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
      }).then((data) => {
        this.submitting = false;
        this.$emit('confirm', data.data.data);
        this.close();
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.modals.add_protocol_steps.success_flash', { count: data.data.data.length }), 'success');
      }).catch(() => {
        this.submitting = false;
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.modals.add_protocol_steps.error_flash'), 'danger');
      });
    }
  }
};
</script>
