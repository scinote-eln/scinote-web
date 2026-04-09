<template>
  <div ref="stepContainer"
       class="step-container p-4 mb-4 rounded pr-8 relative locked"
       :data-id="step.id"
       :class="{
        'bg-white': !step.attributes.archived,
        '!bg-sn-background-brittlebush': step.attributes.archived
      }"
       :data-e2e="`e2e-CO-task-step${step.id}`"
  >
    <div>
      <div class="step-header flex justify-between">
        <div class="step-element-header flex items-start flex-grow gap-4">
          <a ref="toggleElement" class="step-collapse-link hover:no-underline focus:no-underline self-start"
            :href="'#stepBody' + step.id"
            data-toggle="collapse"
            data-remote="true"
            @click="toggleCollapsed"
            :data-e2e="`e2e-BT-protocol-step${step.id}-toggleCollapsed`">
            <span class="sn-icon sn-icon-right "></span>
          </a>
          <InlineEdit
            :value="step.attributes.name"
            class="flex-grow font-bold text-base"
            :class="{ 'pointer-events-none': true }"
            :singleLine="false"
            :characterLimit="255"
            :allowBlank="false"
            :attributeName="`${i18n.t('Step')} ${i18n.t('name')}`"
            :placeholder="i18n.t('protocols.steps.placeholder')"
            :defaultValue="i18n.t('protocols.steps.default_name')"
            :timestamp="i18n.t(`protocols.steps.${step.attributes.archived ? 'timestamp_archived' : 'timestamp'}`, {
              date: step.attributes.archived_on || step.attributes.created_at,
              user: step.attributes.archived_by || step.attributes.created_by
            })"
            :data-e2e="`task-step${step.id}`"
          />
        </div>
        <div class="step-head-right flex elements-actions-container">
          <div v-if="step.attributes.archived" class="sci-tag bg-sn-alert-brittlebush">
            {{ i18n.t('protocols.steps.archived') }}
            <span class="sn-icon sn-icon-archive"></span>
          </div>
          <button
            v-if="this.urls.restore_url"
            class="btn icon-btn btn-light"
            @click="confirmingRestore=true"
            :title="this.i18n.t('protocols.steps.options_dropdown.restore')"
            :data-e2e="`e2e-DO-task-step${this.step.id}-optionsMenu-restore`"
          >
            <i class="sn-icon sn-icon-restore"></i>
          </button>
          <GeneralDropdown v-if="step.attributes.results.length > 0" ref="linkedStepsDropdown"  position="right">
            <template v-slot:field>
              <button
                ref="linkButton"
                class="btn btn-light icon-btn"
                :title="i18n.t('protocols.steps.linked_results')"
              >
                <i class="sn-icon sn-icon-steps"></i>
                <span class="absolute top-1 -right-1 h-4 min-w-4 bg-sn-science-blue text-white flex items-center justify-center rounded-full text-[10px]">
                  {{ step.attributes.results.length }}
                </span>
              </button>
            </template>
            <template v-slot:flyout>
              <div class="overflow-y-auto max-h-[calc(50vh_-_6rem)]">
                <a v-for="result in step.attributes.results"
                  :key="result.id"
                  :title="result.name"
                  :href="resultUrl(result.id, result.archived)"
                  class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer block hover:no-underline text-sn-blue truncate"
                >
                  {{ result.name }}
                </a>
              </div>
            </template>
          </GeneralDropdown>
          <a href="#"
            ref="comments"
            class="open-comments-sidebar btn icon-btn btn-light"
            data-turbolinks="false"
            data-object-type="Step"
            :data-object-id="step.id"
          >
            <i class="sn-icon sn-icon-comments"></i>
            <span class="comments-counter" :class="{ 'hidden': !step.attributes.comments_count }"
                  :id="`comment-count-${step.id}`">
                {{ step.attributes.comments_count }}
            </span>
          </a>
          <button
            v-if="this.urls.delete_url"
            class="btn icon-btn btn-light"
            @click="confirmingDelete=true"
            :title="this.i18n.t('protocols.steps.options_dropdown.delete')"
          >
            <i class="sn-icon sn-icon-delete"></i>
          </button>
        </div>
      </div>
      <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
      <restoreStepModal v-if="confirmingRestore" @confirm="restoreStep" @cancel="closeRestoreModal"/>

      <div class="collapse in pl-10" :id="'stepBody' + step.id">
        <div v-for="(element, index) in orderedElements" :key="element.id">
          <component
            :is="elements[index].attributes.orderable_type"
            class="result-element"
            :element.sync="elements[index]"
            :inRepository="false"
            :assignableMyModuleId="step.attributes.my_module_id"
            @component:delete="removeElement"
            @component:archive="removeElement"
            @component:restore="removeElement"
          />
        </div>
        <Attachments v-if="attachments.length"
                      :parent="step"
                      :archived="true"
                      :attachments="attachments"
                      :attachmentsReady="attachmentsReady"
                      @attachments:openFileModal="showFileModal = true"
                      @attachments:order="changeAttachmentsOrder"
                      @attachment:deleted="attachmentDeleted"
                      @attachments:viewMode="changeAttachmentsViewMode"
                      @attachment:viewMode="updateAttachmentViewMode"/>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import StepTable from '../shared/content/table.vue';
import StepText from '../shared/content/text.vue';
import Checklist from '../shared/content/checklist.vue';
import FormResponse from '../shared/content/form_response.vue';
import Attachments from '../shared/content/attachments.vue';
import InlineEdit from '../shared/inline_edit.vue';
import GeneralDropdown from '../shared/general_dropdown.vue';
import deleteStepModal from './modals/delete_step.vue'
import restoreStepModal from './modals/restore_step.vue'

import AttachmentsMixin from '../shared/content/mixins/attachments.js';
import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js';
import OveMixin from '../shared/content/attachments/mixins/ove.js';
import UtilsMixin from '../mixins/utils.js';
import tooltipMixin from '../mixins/tooltipMixin.js';
import StepCommonMixin from './mixins/step_common.js';

export default {
  name: 'Steps',
  props: {
    step: { type: Object, required: true },
    protocolId: { type: Number, required: false }
  },
  mixins: [tooltipMixin, StepCommonMixin, AttachmentsMixin, WopiFileModal, OveMixin, UtilsMixin],
  components: {
    StepTable,
    StepText,
    Attachments,
    InlineEdit,
    GeneralDropdown,
    deleteStepModal,
    restoreStepModal,
    Checklist,
    FormResponse
  },
  data() {
    return {
      confirmingDelete: false,
      confirmingRestore: false
    }
  },
  methods: {
    closeRestoreModal() {
      this.confirmingRestore = false;
    },
    restoreStep() {
      axios.post(this.urls.restore_url).then((response) => {
        this.closeRestoreModal();
        this.$emit('step:restored', this.step.id, response.data);
      });
    },
    closeDeleteModal() {
      this.confirmingDelete = false;
    },
    deleteStep() {
      axios.delete(this.urls.delete_url).then((response) => {
        this.$emit('step:deleted', this.step.id);
      });
    }
  }
};
</script>
