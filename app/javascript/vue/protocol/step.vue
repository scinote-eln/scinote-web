<template>
  <div ref="stepContainer"
       class="step-container flex flex-col gap-4 p-4 rounded-lg bg-sn-white"
       :id="`stepContainer${step.id}`"
       :data-id="step.id"
       :class="{ 'draging-file': dragingFile, 'editing-name': editingName, 'locked': !urls.update_url, 'pointer-events-none': addingContent }"
       :data-e2e="`e2e-CO-protocol-step${step.id}`"
       @drop.prevent="dropFile"
       @dragenter.prevent="dragEnter($event)"
       @dragover.prevent
  >
    <div class="drop-message" @dragleave.prevent="!showFileModal ? dragingFile = false : null">
      {{ i18n.t('protocols.steps.drop_message', { position: step.attributes.position + 1 }) }}
      <StorageUsage v-if="showStorageUsage()" :parent="step"/>
    </div>

    <!-- Outside the body, so the File tile and Insert menu both reach them whatever the layout -->
    <input type="file" class="hidden" ref="fileSelector" @change="loadFromComputer" multiple />
    <span
      class="new-marvinjs-upload-button hidden"
      :data-object-id="step.id"
      ref="marvinJsButton"
      :data-marvin-url="step.attributes.marvinjs_context?.marvin_js_asset_url"
      :data-object-type="step.attributes.type"
      tabindex="0"
    ></span> <!-- Hidden element to support legacy code -->

    <StepHeader
      :step="step"
      :inRepository="inRepository"
      :isCollapsed="isCollapsed"
      :editingName="editingName"
      @toggle-complete="changeState"
      @toggle-skip="changeSkipped"
      @toggle-collapse="toggleBody"
      @update-name="updateName"
      @editing="editingName = $event"
    />

    <div class="collapse in" :id="'stepBody' + step.id">
      <div class="flex items-start gap-6 rounded-xl bg-sn-super-light-grey" :class="isEmpty ? 'p-6' : 'p-4'">
        <div class="flex flex-col gap-6 grow min-w-0">
          <StepEmptyState
            v-if="isEmpty"
            :stepId="step.id"
            :contentTypes="contentTypes"
            @insert="insertContent"
          />
          <template v-else>
            <MenuDropdown
              v-if="insertMenu.length > 0"
              class="self-start"
              :listItems="insertMenu"
              :btnText="i18n.t('protocols.steps.insert.button')"
              :btnClasses="'btn btn-light btn-lg hover:!bg-sn-light-grey'"
              :position="'left'"
              :caret="true"
              :dataE2e="`e2e-DD-protocol-step${step.id}-insertContent`"
              :disableOverflow="true"
              @dtEvent="(action, item) => insertContent(action, item.params)"
            />
            <component
              v-for="(element, index) in orderedElements"
              :ref="'stepComponent'"
              :is="elements[index].type"
              :key="`${element.id}-${element.type}`"
              class="step-element"
              :element.sync="elements[index]"
              :card="true"
              :inRepository="inRepository"
              :reorderElementUrl="elements.length > 1 ? urls.reorder_elements_url : ''"
              :assignableMyModuleId="assignableMyModuleId"
              :isNew="element.isNew"
              :dataE2e="`protocol-step${step.id}`"
              e2eClass="protocol-step"
              @component:adding-content="($event) => addingContent = $event"
              @component:delete="removeElement"
              @component:archive="removeElement"
              @component:restore="removeElement"
              @update="updateElement"
              @reorder="openReorderModal"
              @component:insert="insertElement"
              @moved="moveElement"
            />
            <Attachments v-if="attachments.length"
                         class="step-element"
                         :card="true"
                         :parent="step"
                         :attachments="attachments"
                         :attachmentsReady="attachmentsReady"
                         :dataE2e="`protocol-step${step.id}`"
                         e2eClass="protocol-step"
                         @attachments:openFileModal="showFileModal = true"
                         @attachment:deleted="attachmentDeleted"
                         @attachment:update="updateAttachment"
                         @attachment:uploaded="loadAttachments"
                         @attachments:order="changeAttachmentsOrder"
                         @attachment:moved="moveAttachment"
                         @attachments:viewMode="changeAttachmentsViewMode"
                         @attachment:viewMode="updateAttachmentViewMode"/>
            <div v-if="!inRepository && (urls.state_url || urls.skip_url)" class="flex flex-wrap gap-2 pt-4">
              <button v-if="urls.state_url"
                      type="button"
                      class="btn btn-light btn-lg hover:!bg-sn-light-grey"
                      :data-e2e="`e2e-BT-protocol-step${step.id}-markAsDone`"
                      @click="changeState">
                <i :class="['sn-icon', step.attributes.completed ? 'sn-icon-task-status-completed' : 'sn-icon-alert-success']"></i>
                {{ step.attributes.completed ? i18n.t('protocols.steps.status.mark_as_not_done') : i18n.t('protocols.steps.status.mark_as_done') }}
              </button>
              <button v-if="urls.skip_url"
                      type="button"
                      class="btn btn-light btn-lg hover:!bg-sn-light-grey"
                      :data-e2e="`e2e-BT-protocol-step${step.id}-skipStep`"
                      @click="changeSkipped">
                <i :class="['sn-icon', step.attributes.skipped_at ? 'sn-icon-skip-fill' : 'sn-icon-skip-outline']"></i>
                {{ step.attributes.skipped_at ? i18n.t('protocols.steps.status.unskip') : i18n.t('protocols.steps.status.skip') }}
              </button>
            </div>
          </template>
        </div>
        <StepRail
          :step="step"
          :inRepository="inRepository"
          :addingStepsLocked="addingStepsLocked"
          :empty="isEmpty"
          :elementsCount="elements.length"
          :resultUrl="resultUrl"
          @duplicate="duplicateStep"
          @archive="showArchiveModal"
          @delete="showDeleteModal"
          @reorder="openReorderModal"
          @link-results="openLinkResultsModal = true"
        />
      </div>
    </div>

    <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
    <archiveStepModal v-if="confirmingArchive" @confirm="archiveStep" @cancel="closeArchiveModal"/>

    <template v-if="step.attributes.urls.lock_url">
      <ManageItemsModal
        v-if="reordering"
        :items="reorderableElements"
        :subject="step"
        @reorder="updateElementOrder"
        @toggle-lock="toggleItemLock"
        @toggle-lock-attachments="toggleAttachmentsLock"
        @close="closeReorderModal"
        dataE2e="protocol-step-manage"
      ></ManageItemsModal>
    </template>
    <template v-else>
      <ReorderableItemsModal v-if="reordering"
        :title="i18n.t('protocols.steps.modals.reorder_elements.title', { step_position: step.attributes.position + 1 })"
        :items="reorderableElements"
        dataE2e="protocol-step-reorder"
        @reorder="updateElementOrder"
        @close="closeReorderModal"
      />
    </template>

    <CustomWellPlateModal v-if="customWellPlate"
      @cancel="closeCustomWellPlateModal"
      @create:table="(...args) => createElement('table', ...args)"
    />

    <SelectFormModal
      v-if="openFormSelectModal"
      @close="openFormSelectModal = false"
      @submit="createElement('form_response', null, null, $event); openFormSelectModal = false"
    />
    <Teleport to="body">
      <LinkResultsModal
        v-if="openLinkResultsModal"
        :step="step"
        @updateStep="updateLinkedResults"
        @close="openLinkResultsModal = false"
      />
    </Teleport>
  </div>
</template>

<script>
import Table from '../shared/content/table.vue';
import StepText from '../shared/content/text.vue';
import Checklist from '../shared/content/checklist.vue';
import FormResponse from '../shared/content/form_response.vue';
import Attachments from '../shared/content/attachments.vue';
import deleteStepModal from './modals/delete_step.vue';
import archiveStepModal from './modals/archive_step.vue';
import LinkResultsModal from './modals/link_results.vue';
import ReorderableItemsModal from '../shared/reorderable_items_modal.vue';
import ManageItemsModal from '../shared/manage_items_modal.vue';
import MenuDropdown from '../shared/menu_dropdown.vue';
import CustomWellPlateModal from '../shared/content/modal/custom_well_plate_modal.vue';
import SelectFormModal from '../shared/content/modal/form_select.vue';
import StorageUsage from '../shared/content/attachments/storage_usage.vue';
import StepHeader from './step/step_header.vue';
import StepRail from './step/step_rail.vue';
import StepEmptyState from './step/step_empty_state.vue';

import UtilsMixin from '../mixins/utils.js';
import AttachmentsMixin from '../shared/content/mixins/attachments.js';
import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js';
import OveMixin from '../shared/content/attachments/mixins/ove.js';
import tooltipMixin from '../mixins/tooltipMixin.js';
import StepCommonMixin from './mixins/step_common.js';
import ContentTypesMixin from './step/content_types.js';
import axios from '../../packs/custom_axios';

export default {
  name: 'StepContainer',
  props: {
    addingStepsLocked: {
      type: Boolean,
      required: true
    },
    step: {
      type: Object,
      required: true
    },
    inRepository: {
      type: Boolean,
      required: true
    },
    reorderStepUrl: {
      required: false
    },
    assignableMyModuleId: {
      type: Number,
      required: false
    },
    stepToReload: {
      type: Number,
      required: false
    },
    activeDragStep: {
      required: false
    }
  },
  data() {
    return {
      confirmingArchive: false,
      addingContent: false,
      showFileModal: false,
      dragingFile: false,
      reordering: false,
      editingName: false,
      customWellPlate: false,
      openFormSelectModal: false,
      openLinkResultsModal: false
    };
  },
  mixins: [UtilsMixin, AttachmentsMixin, WopiFileModal, OveMixin, tooltipMixin, StepCommonMixin, ContentTypesMixin],
  components: {
    Table,
    StepText,
    Checklist,
    FormResponse,
    Attachments,
    deleteStepModal,
    archiveStepModal,
    LinkResultsModal,
    ReorderableItemsModal,
    ManageItemsModal,
    MenuDropdown,
    CustomWellPlateModal,
    SelectFormModal,
    StorageUsage,
    StepHeader,
    StepRail,
    StepEmptyState
  },
  watch: {
    step() {
      this.elements = this.step.elements;
      this.attachments = this.step.attachments;
    },
    stepToReload() {
      if (this.stepToReload == this.step.id) {
        this.loadElements();
        this.loadAttachments();
      }
    },
    activeDragStep() {
      if (this.activeDragStep != this.step.id && this.dragingFile) {
        this.dragingFile = false;
      }
    }
  },
  computed: {
    reorderableElements() {
      return this.orderedElements.map((e) => ({ id: e.id, attributes: e }));
    },
    orderedElements() {
      return this.elements.sort((a, b) => (a.position) - (b.position));
    },
    urls() {
      return this.step.attributes.urls || {};
    },
    isEmpty() {
      return this.elements.length === 0 && this.attachments.length === 0;
    },
    cantUploadFiles() {
      return !this.inRepository && (this.step.attributes.attachments_locked || this.step.attributes.locked);
    }
  },
  methods: {
    // Runs an Insert-menu or empty-tile action (the emits from the content_types mixin)
    insertContent(action, params) {
      const actions = {
        'create:text': () => this.createElement('text'),
        'create:table': () => this.createElement('table', params),
        'create:checklist': () => this.createElement('checklist'),
        'create:form': () => { this.openFormSelectModal = true; },
        'create:custom_well_plate': () => this.openCustomWellPlateModal(),
        'create:file': () => this.openLoadFromComputer(),
        'create:wopi_file': () => this.openWopiFileModal(),
        'create:ove_file': () => this.openOVEditor(),
        'create:marvinjs_file': () => this.openMarvinJsModal(this.$refs.marvinJsButton)
      };
      actions[action]?.();
    },
    // Bootstrap animates the body; isCollapsed drives the chevron and the saved setting
    toggleBody() {
      $(`#stepBody${this.step.id}`).collapse(this.isCollapsed ? 'show' : 'hide');
      this.toggleCollapsed();
    },
    // Overrides the attachments mixin, which expects a $refs.toggleElement link
    toggleCollapsedSection() {
      if (this.isCollapsed) {
        this.toggleBody();
      }
    },
    dragEnter(e) {
      if (this.showFileModal || !this.urls.upload_attachment_url || this.cantUploadFiles) return;

      // Detect if dragged element is a file
      // https://stackoverflow.com/a/8494918
      const dt = e.dataTransfer;
      if (dt.types && (dt.types.indexOf ? dt.types.indexOf('Files') != -1 : dt.types.contains('Files'))) {
        this.dragingFile = true;
        this.$emit('step:drag_enter', this.step.id);
      }
    },
    showStorageUsage() {
      return (this.elements.length || this.attachments.length) && !this.isCollapsed && this.step.attributes.storage_limit;
    },
    showDeleteModal() {
      this.confirmingDelete = true;
    },
    closeDeleteModal() {
      this.confirmingDelete = false;
    },
    deleteStep() {
      axios.delete(this.urls.delete_url).then((response) => {
        this.$emit('step:delete', response.data.data, 'delete');
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    showArchiveModal() {
      if (this.elements.some((e) => e.type === 'Table')) {
        this.confirmingArchive = true;
      } else {
        this.archiveStep();
      }
    },
    closeArchiveModal() {
      this.confirmingArchive = false;
    },
    archiveStep() {
      axios.post(this.urls.archive_url).then((response) => {
        this.$emit('step:archived', response.data.data, 'archive', this.step.attributes.position);
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    toggleAttachmentsLock() {
      axios.patch(this.urls.update_url, {
        step: { attachments_locked: !this.step.attributes.attachments_locked }
      }).then((response) => {
        this.$emit('step:update', {
          position: this.step.attributes.position,
          attachments_locked: response.data.data.attributes.attachments_locked
        });
        this.loadAttachments();
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    emitStateUpdate(extra = {}) {
      this.$emit('step:update', {
        completed: this.step.attributes.completed,
        position: this.step.attributes.position,
        skipped_at: this.step.attributes.skipped_at,
        ...extra
      });
    },
    // Both toggle endpoints render StepSerializer, which carries the refreshed status timestamp
    applyStatusTimestamp(response) {
      this.emitStateUpdate({ status_timestamp: response.data.data.attributes.status_timestamp });
    },
    changeState() {
      if (!this.urls.state_url) return;

      const currentSkipStatus = this.step.attributes.skipped_at;

      this.step.attributes.completed = !this.step.attributes.completed;

      if (this.step.attributes.skipped_at && this.isCollapsed) {
        this.toggleBody();
      }

      this.step.attributes.skipped_at = null;
      this.emitStateUpdate();
      axios.post(this.urls.state_url, { completed: this.step.attributes.completed })
        .then(this.applyStatusTimestamp)
        .catch(() => {
          this.step.attributes.completed = !this.step.attributes.completed;
          this.step.attributes.skipped_at = currentSkipStatus;
          this.emitStateUpdate();
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
    },
    changeSkipped() {
      if (!this.urls.skip_url) return;

      const currentCompleteStatus = this.step.attributes.completed;

      this.step.attributes.skipped_at = !this.step.attributes.skipped_at;
      this.step.attributes.completed = false;
      this.emitStateUpdate();

      if ((this.step.attributes.skipped_at && !this.isCollapsed) || (!this.step.attributes.skipped_at && this.isCollapsed)) {
        this.toggleBody();
      }

      axios.post(this.urls.skip_url, { skipped: this.step.attributes.skipped_at })
        .then(this.applyStatusTimestamp)
        .catch(() => {
          this.step.attributes.skipped_at = !this.step.attributes.skipped_at;
          this.step.attributes.completed = currentCompleteStatus;
          this.emitStateUpdate();
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
    },
    updateElement(element, skipRequest = false, callback = null) {
      const index = this.elements.findIndex((e) => e.id === element.id && e.type === element.type);

      if (!this.elements[index]) return;

      element.isNew = false;

      if (skipRequest || !element.urls?.update_url) {
        this.elements.splice(index, 1, element);
        this.$emit('stepUpdated');
      } else {
        axios.put(element.urls.update_url, element).then((result) => {
          this.elements.splice(index, 1, result.data);
          this.$emit('stepUpdated');

          // optional callback after successful update
          if (typeof callback === 'function') {
            callback();
          }
        }).catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general_saving_data'), 'danger');
        });
      }
    },
    updateElementOrder(orderedElements) {
      orderedElements.forEach((element, position) => {
        const index = this.elements.findIndex((e) => e.id === element.id && e.type === element.attributes.type);
        this.elements[index].position = position;
      });

      const elementPositions = {
        step_orderable_element_positions: this.elements.map(
          (element) => [element.step_orderable_element_id, element.position]
        )
      };

      axios.post(this.urls.reorder_elements_url, elementPositions)
        .then(() => this.$emit('stepUpdated'))
        .catch(() => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger'));
    },
    updateName(newName) {
      axios.patch(this.urls.update_url, { step: { name: newName } }).then((response) => {
        this.$emit('step:update', {
          name: response.data.data.attributes.name,
          status_timestamp: response.data.data.attributes.status_timestamp,
          position: this.step.attributes.position
        });
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response?.data?.errors ? Object.values(error.response.data.errors).join(', ') : this.i18n.t('errors.general'), 'danger');
      });
    },
    toggleItemLock(item) {
      const url = item.attributes.locked ? item.attributes.urls.unlock_url : item.attributes.urls.lock_url;
      axios.post(url).then(() => {
        item.attributes.locked = !item.attributes.locked;
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    createElement(elementType, tableDimensions = null, name = '', formId = null) {
      const plateTemplate = tableDimensions != null;
      tableDimensions ||= [5, 8];
      axios.post(this.urls[`create_${elementType}_url`], {
        tableDimensions, plateTemplate, name, form_id: formId
      }).then((response) => {
        const result = response.data;
        result.isNew = true;
        this.elements.push(result);

        if (this.isCollapsed) {
          this.toggleBody();
        }
        this.$emit('stepUpdated');

        this.$parent.$nextTick(() => {
          const children = this.$refs.stepContainer.querySelectorAll('.step-element');
          const lastChild = children[children.length - 1];

          lastChild.scrollIntoView(false);
          window.scrollBy({
            top: 200,
            behavior: 'smooth'
          });
        });
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    openCustomWellPlateModal() {
      this.customWellPlate = true;
    },
    closeCustomWellPlateModal() {
      this.customWellPlate = false;
    },
    updateAttachment(attachment) {
      const index = this.attachments.findIndex((a) => a.id === attachment.id);
      if (index !== -1) {
        this.attachments[index] = attachment;
        this.$emit('stepUpdated');
      }
    },
    openReorderModal() {
      this.reordering = true;
    },
    closeReorderModal() {
      this.reordering = false;
    },
    insertElement(element) {
      const { position } = element;
      this.elements = this.elements.map((s) => {
        if (s.position >= position) {
          s.position += 1;
        }
        return s;
      });
      this.elements.push(element);
      this.$emit('stepUpdated');
    },
    moveElement(position, targetId) {
      this.elements.splice(position, 1);
      this.elements.forEach((e) => {
        if (e.position >= position) {
          e.position -= 1;
        }
      });
      this.$emit('stepUpdated');
      this.$emit('step:move_element', targetId);
    },
    moveAttachment(id, targetId) {
      this.attachments = this.attachments.filter((a) => a.id !== id);
      this.$emit('stepUpdated');
      this.$emit('step:move_attachment', targetId);
    },
    duplicateStep() {
      axios.post(this.urls.duplicate_step_url).then((response) => {
        const result = response.data;
        const step = result.data;
        step.attachments = [];
        result.included?.forEach((included) => {
          if (included.type === 'assets') {
            step.attachments.push(included);
          }
        });
        step.elements = step.attributes.elements || [];
        this.$emit('step:insert', result.data);
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.step_duplicated'), 'success');
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.step_duplication_failed'), 'danger');
      });
    },
    updateLinkedResults(results) {
      this.$emit('step:update', {
        results,
        position: this.step.attributes.position
      });
    }
  }
};
</script>
