<template>
  <div ref="resultContainer"
       class="result-wrapper p-4 mb-4 rounded pr-8 relative"
       :data-id="result.id"
       :class="{
        'bg-white': !result.attributes.archived,
        'locked': locked,
        '!bg-sn-background-brittlebush': result.attributes.archived
      }"
       :data-e2e="`e2e-CO-task-result${result.id}`"
  >
    <div>
      <div class="result-header flex justify-between">
        <div class="result-head-left flex items-start flex-grow gap-4">
          <a ref="toggleElement" class="result-collapse-link hover:no-underline focus:no-underline py-0.5 border-0 border-y border-transparent border-solid text-sn-black"
              :href="'#resultBody' + result.id"
              data-toggle="collapse"
              data-remote="true"
              :data-e2e="`e2e-BT-task-result${result.id}-visibilityToggle`"
              @click="toggleCollapsed">
            <span class="sn-icon sn-icon-right "></span>
          </a>
          <InlineEdit
            :value="result.attributes.name"
            class="flex-grow font-bold text-base"
            :class="{ 'pointer-events-none': true }"
            :singleLine="false"
            :characterLimit="255"
            :allowBlank="false"
            :attributeName="`${i18n.t('Result')} ${i18n.t('name')}`"
            :placeholder="i18n.t('my_modules.results.placeholder')"
            :defaultValue="i18n.t('my_modules.results.default_name')"
            :timestamp="i18n.t(`protocols.steps.${result.attributes.archived ? 'timestamp_archived' : 'timestamp'}`, {
              date: result.attributes.archived_on || result.attributes.created_at,
              user: result.attributes.archived_by || result.attributes.created_by
            })"
            :data-e2e="`task-result${result.id}`"
          />
        </div>
        <div class="result-head-right flex elements-actions-container">
          <div v-if="result.attributes.archived" class="sci-tag bg-sn-alert-brittlebush">
            {{ i18n.t('my_modules.results.archived') }}
            <span class="sn-icon sn-icon-archive"></span>
          </div>
          <button
            v-if="this.urls.restore_url"
            class="btn icon-btn btn-light"
            @click="confirmingRestore = true"
            :title="this.i18n.t('my_modules.results.actions.restore')"
            :data-e2e="`e2e-DO-task-result${this.result.id}-optionsMenu-restore`"
          >
            <i class="sn-icon sn-icon-restore"></i>
          </button>
          <GeneralDropdown v-if="result.attributes.steps.length > 0" ref="linkedStepsDropdown"  position="right">
            <template v-slot:field>
              <button
                ref="linkButton"
                class="btn btn-light icon-btn"
                :title="i18n.t('my_modules.results.linked_steps')"
                :data-e2e="`e2e-DD-task-result${result.id}-linkStep-showLinked`"
              >
                <i class="sn-icon sn-icon-steps"></i>
                <span class="absolute top-1 -right-1 h-4 min-w-4 bg-sn-science-blue text-white flex items-center justify-center rounded-full text-[10px]">
                  {{ result.attributes.steps.length }}
                </span>
              </button>
            </template>
            <template v-slot:flyout>
              <div class="overflow-y-auto max-h-[calc(50vh_-_6rem)]">
                <a v-for="step in result.attributes.steps"
                  :key="step.id"
                  :title="step.name"
                  :href="protocolUrl(step.id)"
                  class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer block hover:no-underline text-sn-blue truncate"
                  :data-e2e="`e2e-BT-task-result${result.id}-linkStep-step${step.id}`"
                >
                  {{ step.name }}
                </a>
              </div>
            </template>
          </GeneralDropdown>
          <a href="#"
            v-if="result.attributes.type == 'Result'"
            ref="comments"
            class="open-comments-sidebar btn icon-btn btn-light"
            data-turbolinks="false"
            data-object-type="Result"
            :data-object-id="result.id"
            :data-e2e="`e2e-BT-task-result${result.id}-comments`"
          >
            <i class="sn-icon sn-icon-comments"></i>
            <span class="comments-counter" :class="{ 'hidden': !result.attributes.comments_count }"
                  :id="`comment-count-${result.id}`">
                {{ result.attributes.comments_count }}
            </span>
          </a>
          <button
            v-if="this.urls.delete_url"
            class="btn icon-btn btn-light"
            @click="showDeleteModal"
            :title="this.i18n.t('my_modules.results.actions.delete')"
            :data-e2e="`e2e-DO-task-result${this.result.id}-optionsMenu-delete`"
          >
            <i class="sn-icon sn-icon-delete"></i>
          </button>
        </div>
      </div>
      <deleteResultModal v-if="confirmingDelete" @confirm="deleteResult" @cancel="closeDeleteModal"/>
      <restoreResultModal v-if="confirmingRestore" @confirm="restoreResult" @cancel="closeRestoreModal"/>

      <div class="collapse in pl-10" :id="'resultBody' + result.id">
        <div v-for="(element, index) in orderedElements" :key="element.id">
          <component
            :is="elements[index].attributes.orderable_type"
            class="result-element"
            :element.sync="elements[index]"
            :inRepository="false"
            :reorderElementUrl="elements.length > 1 ? urls.reorder_elements_url : ''"
            :assignableMyModuleId="result.attributes.my_module_id"
            :isNew="element.isNew"
            @component:adding-content="($event) => addingContent = $event"
            @component:delete="removeElement"
            @component:archive="removeElement"
            @component:restore="removeElement"
            @update="updateElement"
            @reorder="openReorderModal"
            @component:insert="insertElement"
            @moved="moveElement"
          />
        </div>
        <Attachments v-if="attachments.length"
                      :parent="result"
                      :archived="true"
                      :attachments="attachments"
                      :attachmentsReady="attachmentsReady"
                      @attachments:openFileModal="showFileModal = true"
                      @attachment:deleted="attachmentDeleted"
                      @attachments:order="changeAttachmentsOrder"
                      @attachments:viewMode="changeAttachmentsViewMode"
                      @attachment:viewMode="updateAttachmentViewMode"/>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import ResultTable from '../shared/content/table.vue';
import ResultText from '../shared/content/text.vue';
import Attachments from '../shared/content/attachments.vue';
import InlineEdit from '../shared/inline_edit.vue';
import MenuDropdown from '../shared/menu_dropdown.vue';
import GeneralDropdown from '../shared/general_dropdown.vue';
import deleteResultModal from './delete_result.vue';
import restoreResultModal from './modals/restore_result.vue';

import AttachmentsMixin from '../shared/content/mixins/attachments.js';
import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js';
import OveMixin from '../shared/content/attachments/mixins/ove.js';
import UtilsMixin from '../mixins/utils.js';
import ResultCommonMixin from './mixins/result_common.js';
import DeleteMixin from '../shared/content/mixins/delete.js';

export default {
  name: 'Results',
  props: {
    result: { type: Object, required: true },
    resultToReload: { type: Number, required: false },
    protocolId: { type: Number, required: false }
  },
  mixins: [UtilsMixin, AttachmentsMixin, WopiFileModal, OveMixin, ResultCommonMixin, DeleteMixin],
  components: {
    ResultTable,
    ResultText,
    Attachments,
    InlineEdit,
    MenuDropdown,
    deleteResultModal,
    GeneralDropdown,
    restoreResultModal
  },
  data() {
    return {
      confirmingDelete: false,
      confirmingRestore: false
    };
  },
  methods: {
    closeRestoreModal() {
      this.confirmingRestore = false;
    },
    restoreResult() {
      axios.post(this.urls.restore_url).then((response) => {
        this.$emit('result:restored', this.result.id);
      });
    }
  }
};
</script>
