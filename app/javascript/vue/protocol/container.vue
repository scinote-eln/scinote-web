<template>
  <div>
    <div v-if="protocol.id" class="task-protocol">
      <div ref="header" class="task-section-header ml-[-1rem] w-[calc(100%_+_2rem)] px-4 bg-sn-white sticky top-0 transition" v-if="!inRepository">
        <div class="portocol-header-left-part grow" :class="{'overflow-hidden': headerSticked && moduleName}">
          <template v-if="headerSticked && moduleName">
            <i class="sn-icon sn-icon-navigator sci--layout--navigator-open cursor-pointer p-1.5 border rounded border-sn-light-grey mr-4"></i>
            <div @click="scrollTop" class="task-section-title  min-w-[5rem] cursor-pointer" :data-sn-tooltip="moduleName">
              <h2 class="truncate leading-6">{{ moduleName }}</h2>
            </div>
          </template>
          <template v-else>
            <a class="task-section-caret"
              tabindex="0"
              role="button"
              data-toggle="collapse"
              href="#protocol-content"
              aria-expanded="true"
              aria-controls="protocol-content"
              data-e2e="e2e-IC-task-protocol-visibilityToggle"
            >
              <i class="sn-icon sn-icon-right"></i>
              <div class="task-section-title truncate">
                <h2 data-e2e="e2e-TX-task-protocol-sectionTitle">{{ i18n.t('Protocol') }}</h2>
              </div>
            </a>
          </template>
          <div :class="{'hidden': headerSticked}">
            <div class="my-module-protocol-status">
              <!-- protocol status dropdown gets mounted here -->
            </div>
          </div>
        </div>
        <div class="actions-block">
          <div class="protocol-buttons-group shrink-0 bg-sn-white">
            <button v-if="urls.add_step_url || addingStepsLocked"
              class="btn btn-secondary icon-btn xl:!px-4"
              :disabled="addingStepsLocked"
              :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : i18n.t('protocols.steps.new_step_title')"
              @keyup.enter="addStep(steps.length)"
              @click="addStep(steps.length)"
              tabindex="0"
              data-e2e="e2e-BT-task-protocol-newStep">
                <span class="sn-icon sn-icon-new-task" aria-hidden="true"></span>
                <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.new_step") }}</span>
            </button>
            <button
              v-if="!inRepository && permissions.can_manage_protocol_in_module"
              class="btn btn-secondary icon-btn xl:!px-4"
              @click="showRepositoriesModal = true"
              :data-sn-tooltip="i18n.t('protocols.steps.show_repositories')"
              data-e2e="e2e-BT-task-protocol-assignedItems"
            >
              <span class="sn-icon sn-icon-inventory" aria-hidden="true"></span>
              <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.show_repositories") }}</span>
            </button>
            <template v-if="steps.length > 0">
              <button
                :data-sn-tooltip="i18n.t('protocols.steps.collapse_label')"
                v-if="!stepCollapsed"
                class="btn btn-secondary icon-btn xl:!px-4"
                @click="collapseSteps"
                tabindex="0"
                data-e2e="e2e-BT-task-protocol-collapseAll"
              >
                <i class="sn-icon sn-icon-collapse-all"></i>
                <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.collapse_label") }}</span>
              </button>
              <button v-else
                :data-sn-tooltip="i18n.t('protocols.steps.expand_label')"
                class="btn btn-secondary icon-btn xl:!px-4"
                @click="expandSteps"
                tabindex="0"
                data-e2e="e2e-BT-task-protocol-expandAll"
              >
                <i class="sn-icon sn-icon-expand-all"></i>
                <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.expand_label") }}</span>
              </button>
            </template>
            <ProtocolOptions
              v-if="protocol.attributes && protocol.attributes.urls"
              :protocol="protocol"
              :inRepository="inRepository"
              :addingStepsLocked="addingStepsLocked"
              @protocol:archive_steps="archiveSteps"
              @protocol:add_protocol_steps="addSteps"
              :canDeleteSteps="false"
              :canArchiveSteps="steps.length > 0 && urls.archive_steps_url !== null"
            />
            <button
              class="btn btn-light icon-btn"
              data-toggle="modal"
              data-target="#print-protocol-modal"
              :data-sn-tooltip="i18n.t('protocols.print_label')"
              tabindex="0"
              data-e2e="e2e-BT-task-protocol-print"
            >
              <span class="sn-icon sn-icon-printer" aria-hidden="true"></span>
            </button>
            <a v-if="steps.length > 0 && urls.reorder_steps_url"
              class="btn btn-light icon-btn"
              data-toggle="modal"
              @click="startStepReorder"
              @keyup.enter="startStepReorder"
              :data-sn-tooltip="i18n.t('protocols.rearrange_steps_label')"
              :class="{'disabled': steps.length == 1}"
              tabindex="0"
              data-e2e="e2e-BT-task-protocol-reorderSteps"
            >
                <i class="sn-icon sn-icon-sort" aria-hidden="true"></i>
            </a>
          </div>
        </div>
      </div>
      <div
        id="protocol-content"
        class="protocol-content collapse in"
        aria-expanded="true"
        data-e2e="e2e-CO-task-protocol-content"
      >
        <div class="sci-divider" v-if="!inRepository"></div>
        <div class="mb-4">
          <div class="protocol-name mt-4" v-if="!inRepository">
            <InlineEdit
              v-if="urls.update_protocol_name_url"
              :value="protocol.attributes.name"
              :characterLimit="255"
              :placeholder="i18n.t('my_modules.protocols.protocol_status_bar.enter_name')"
              :allowBlank="!inRepository"
              :attributeName="`${i18n.t('Protocol')} ${i18n.t('name')}`"
              @update="updateName"
              :dataE2e="'task-protocol-title'"
            />
            <span v-else>
              {{ protocol.attributes.name }}
            </span>
          </div>
          <ProtocolMetadata v-if="protocol.attributes && protocol.attributes.in_repository" :protocol="protocol" @update="updateProtocol"/>
          <div :class="inRepository ? 'protocol-section protocol-information' : ''">
            <div v-if="inRepository" id="protocol-description" class="protocol-section-header">
              <div class="protocol-description-container w-full flex flex-row items-center justify-between">
                <a class="protocol-section-caret"
                  role="button"
                  data-toggle="collapse"
                  href="#protocol-description-container"
                  aria-expanded="false"
                  aria-controls="protocol-description-container">
                  <i class="sn-icon sn-icon-right"></i>
                  <span id="protocolDescriptionLabel" class="protocol-section-title" data-e2e="e2e-TX-protocolTemplates-protocolDescription-title">
                    <h2>
                      {{ i18n.t("protocols.header.protocol_description") }}
                    </h2>
                  </span>
                </a>
                <div class="flex flex-row items-center gap-2">
                  <LockedTag v-if="protocol.attributes.description_locked" />
                  <a v-if="urls.update_description_locked_url"
                    class="btn icon-btn"
                    data-e2e="e2e-BT-protocol-templateDescription-lock"
                    :data-sn-tooltip="protocol.attributes.description_locked ? i18n.t('protocols.header.unlock_description') : i18n.t('protocols.header.lock_description')"
                    @click="toggleDescriptionLock"
                    tabindex="0">
                    <i class="sn-icon" :class="{ 'sn-icon-unlocked': !protocol.attributes.description_locked, 'sn-icon-locked-fill': protocol.attributes.description_locked }" aria-hidden="true"></i>
                  </a>
                </div>
              </div>
            </div>
            <div v-if="!inRepository && protocol.attributes.description_locked" class="w-full flex flex-row items-center justify-end mb-1">
              <LockedTag />
            </div>
            <div id="protocol-description-container"
              class="text-base content__text-container"
              :class=" inRepository ? 'protocol-description collapse in' : ''"
              data-e2e="e2e-IF-protocolTemplates-protocolDescription-content">
              <div v-if="urls.update_protocol_description_url">
                <Tinymce
                  :value="protocol.attributes.description"
                  :value_html="protocol.attributes.description_view"
                  :placeholder="i18n.t('my_modules.protocols.protocol_status_bar.empty_description_edit_label')"
                  :updateUrl="urls.update_protocol_description_url"
                  :objectType="'Protocol'"
                  :objectId="parseInt(protocol.id)"
                  :fieldName="'protocol[description]'"
                  :lastUpdated="protocol.attributes.updated_at"
                  :assignableMyModuleId="protocol.attributes.assignable_my_module_id"
                  :characterLimit="1000000"
                  @update="updateDescription"
                />
              </div>
              <div v-else-if="protocol.attributes.description_view" v-html="wrappedTables" class="view-text-element"></div>
              <div v-else class="empty-protocol-description">
                {{ i18n.t("protocols.no_text_placeholder") }}
              </div>
            </div>
          </div>
        </div>
        <div :class="inRepository ? 'protocol-section protocol-steps-section protocol-information' : ''">
          <div v-if="inRepository" id="protocol-steps" class="protocol-section-header">
            <div class="protocol-steps-container w-full flex flex-row items-center justify-between">
              <a class="protocol-section-caret" role="button" data-toggle="collapse" href="#protocol-steps-container" aria-expanded="false" aria-controls="protocol-steps-container">
                <i class="sn-icon sn-icon-right"></i>
                <span id="protocolStepsLabel" class="protocol-section-title" data-e2e="e2e-TX-protocol-templateSteps-title">
                  <h2>
                    {{ i18n.t("protocols.header.protocol_steps") }}
                  </h2>
                </span>
              </a>
              <ProtocolOptions
                v-if="protocol.attributes && protocol.attributes.urls"
                :protocol="protocol"
                :inRepository="inRepository"
                :addingStepsLocked="addingStepsLocked"
                @protocol:delete_steps="deleteSteps"
                @protocol:add_protocol_steps="addSteps"
                :canDeleteSteps="steps.length > 0 && urls.delete_steps_url !== null"
                :canArchiveSteps="false"
              />
            </div>
          </div>
          <div class="sci-divider my-4" v-if="!inRepository"></div>
          <div id="protocol-steps-container" :class=" inRepository ? 'protocol-steps collapse in' : ''">
            <div v-if="inRepository" class="py-5 flex flex-row gap-8 justify-between">
              <a
                v-if="urls.add_step_url"
                class="btn btn-secondary"
                :data-sn-tooltip="i18n.t('protocols.steps.new_step_title')"
                data-e2e="e2e-BT-protocol-templateSteps-newStepTop"
                @keyup.enter="addStep(steps.length)"
                @click="addStep(steps.length)"
                tabindex="0">
                  <span class="sn-icon sn-icon-new-task" aria-hidden="true"></span>
                  <span>{{ i18n.t("protocols.steps.new_step") }}</span>
              </a>
              <div v-if="steps.length > 0" class="ml-auto flex justify-between items-center gap-4">
                <button
                  :data-sn-tooltip="i18n.t('protocols.steps.collapse_label')"
                  v-if="!stepCollapsed"
                  class="btn btn-secondary icon-btn xl:!px-4"
                  @click="collapseSteps"
                  tabindex="0"
                  data-e2e="e2e-BT-task-protocol-collapseAll"
                >
                  <i class="sn-icon sn-icon-collapse-all"></i>
                  <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.collapse_label") }}</span>
                </button>
                <button v-else
                  :data-sn-tooltip="i18n.t('protocols.steps.expand_label')"
                  class="btn btn-secondary icon-btn xl:!px-4"
                  @click="expandSteps"
                  tabindex="0"
                  data-e2e="e2e-BT-task-protocol-expandAll"
                >
                  <i class="sn-icon sn-icon-expand-all"></i>
                  <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.expand_label") }}</span>
                </button>
                <template v-if="inRepository && urls.lock_all_steps_url">
                  <a class="btn btn-light icon-btn"
                     data-toggle="modal"
                     data-e2e="e2e-BT-protocol-templateSteps-manage"
                     :data-sn-tooltip="i18n.t('protocols.manage_steps')"
                     @click="managingSteps = true"
                     @keyup.enter="managingSteps = true"
                     tabindex="0">
                    <i class="sn-icon sn-icon-steps-manage" aria-hidden="true"></i>
                  </a>
                </template>
                <template v-else>
                  <a v-if="steps.length > 0 && urls.reorder_steps_url"
                    class="btn btn-light icon-btn"
                    data-toggle="modal"
                    data-e2e="e2e-BT-protocol-templateSteps-reorder"
                    :data-sn-tooltip="i18n.t('protocols.rearrange_steps_label')"
                    @click="steps.length > 1 && startStepReorder()"
                    @keyup.enter="startStepReorder"
                    :class="{'disabled': steps.length == 1}"
                    tabindex="0" >
                    <i class="sn-icon sn-icon-sort" aria-hidden="true"></i>
                  </a>
                </template>
              </div>
            </div>
            <div :class="{
                'tw-hidden': loadingOverlay
              }"
              class="protocol-steps pb-8"
            >
              <div v-for="(step, index) in steps" :key="step.id" class="step-block">
                <template v-if="urls.reorder_steps_url">
                  <div v-if="index > 0 && urls.add_step_url && urls.reorder_steps_url" class="insert-step" @click="addStep(index)" data-e2e="e2e-BT-protocol-templateSteps-insertStep">
                    <i class="sn-icon sn-icon-new-task"></i>
                    <span class="mr-3">{{ i18n.t("protocols.steps.add_step") }}</span>
                  </div>
                </template>
                <template v-else-if="index > 0 && urls.add_step_url">
                  <div class="insert-step disabled"  :data-sn-tooltip="i18n.t('protocols.action_disabled')">
                    <i class="sn-icon sn-icon-new-task"></i>
                    <span class="mr-3">{{ i18n.t("protocols.steps.add_step") }}</span>
                  </div>
                </template>
                <Step
                  ref="steps"
                  :step.sync="steps[index]"
                  :addingStepsLocked="addingStepsLocked"
                  @reorder="startStepReorder"
                  :inRepository="inRepository"
                  :stepToReload="stepToReload"
                  :activeDragStep="activeDragStep"
                  @step:delete="updateStepsPosition"
                  @step:update="updateStep"
                  @stepUpdated="refreshProtocolStatus"
                  @step:insert="updateStepsPosition"
                  @step:archived="updateStepsPosition"
                  @step:elements:loaded="stepToReload = null; elementsLoaded++"
                  @step:move_element="reloadStep"
                  @step:attachments:loaded="stepToReload = null; attachmentsLoaded++"
                  @step:move_attachment="reloadStep"
                  @step:drag_enter="dragEnter"
                  @step:collapsed="checkStepsState"
                  :reorderStepUrl="steps.length > 1 ? urls.reorder_steps_url : null"
                  :assignableMyModuleId="protocol.attributes.assignable_my_module_id"
                />
                <div v-if="(index === steps.length - 1) && urls.add_step_url" class="insert-step" @click="addStep(index + 1)" data-e2e="e2e-BT-protocol-templateSteps-insertStep">
                  <i class="sn-icon sn-icon-new-task"></i>
                  <span class="mr-3">{{ i18n.t("protocols.steps.add_step") }}</span>
                </div>
              </div>
              <div v-if="steps.length > 0 && urls.add_step_url && inRepository" class="py-5">
                <a
                  class="btn btn-secondary"
                  :data-sn-tooltip="i18n.t('protocols.steps.new_step_title')"
                  data-e2e="e2e-BT-protocol-templateSteps-newStepBottom"
                  @keyup.enter="addStep(steps.length)"
                  @click="addStep(steps.length)"
                  tabindex="0">
                    <span class="sn-icon sn-icon-new-task" aria-hidden="true"></span>
                    <span>{{ i18n.t("protocols.steps.new_step") }}</span>
                </a>
              </div>
            </div>
            <div v-if="loadingOverlay" class="text-center h-20 flex items-center justify-center">
              <div class="sci-loader"></div>
            </div>
          </div>
        </div>
      </div>
      <ReorderableItemsModal v-if="reordering"
        :title="i18n.t('protocols.reorder_steps.modal.title')"
        :items="steps"
        :includeNumbers="true"
        dataE2e="protocol-reorderSteps"
        @reorder="updateStepOrder"
        @close="closeStepReorderModal"
      />
      <ManageStepsModal v-if="managingSteps"
        :steps="steps"
        :protocol="protocol"
        @toggle-lock="toggleStepLock"
        @toggle-lock-all="toggleLockAllSteps"
        @reorder="updateStepOrder"
        @close="managingSteps = false"
      />
      <clipboardPasteModal v-if="showClipboardPasteModal"
                          :image="pasteImages"
                          :objects="steps"
                          :objectType="'step'"
                          :selectedObjectId="firstObjectInViewport()"
                          @files="uploadFilesToStep"
                          @cancel="showClipboardPasteModal = false"
      />
      <AssignedItemsModal
        v-if="showRepositoriesModal"
        :myModuleId="protocol.attributes.assignable_my_module_id.toString()"
        @close="showRepositoriesModal = false"
      />
    </div>
  </div>
</template>

<script>
import InlineEdit from '../shared/inline_edit.vue';
import Step from './step';
import ProtocolMetadata from './protocolMetadata';
import ProtocolOptions from './protocolOptions';
import Tinymce from '../shared/tinymce.vue';
import ReorderableItemsModal from '../shared/reorderable_items_modal.vue';
import ManageStepsModal from './modals/manage_steps.vue';
import clipboardPasteModal from '../shared/content/attachments/clipboard_paste_modal.vue';
import AssetPasteMixin from '../shared/content/attachments/mixins/paste.js';
import UtilsMixin from '../mixins/utils.js';
import stackableHeadersMixin from '../mixins/stackableHeadersMixin';
import moduleNameObserver from '../mixins/moduleNameObserver';
import AssignedItemsModal from './modals/assigned_items.vue';
import tooltipMixin from '../mixins/tooltipMixin.js';
import StepCollapseState from './mixins/step_collapse_state.js';
import axios from '../../packs/custom_axios.js';
import { protocol_filter_global_activities_path } from '../../routes.js';
import LockedTag from '../shared/snippets/locked_tag.vue';

export default {
  name: 'ProtocolContainer',
  props: {
    protocolUrl: {
      type: String,
      required: true
    }
  },
  components: {
    Step, InlineEdit, ProtocolOptions, Tinymce,
    ReorderableItemsModal, ProtocolMetadata, clipboardPasteModal,
    AssignedItemsModal, ManageStepsModal, LockedTag
  },
  mixins: [UtilsMixin, stackableHeadersMixin, moduleNameObserver, AssetPasteMixin, tooltipMixin, StepCollapseState],
  computed: {
    wrappedTables() {
      return window.wrapTables(this.protocol.attributes.description_view);
    },
    inRepository() {
      return this.protocol.attributes.in_repository;
    },
    linked() {
      return this.protocol.attributes.linked;
    },
    urls() {
      return this.protocol.attributes.urls || {};
    },
    permissions() {
      return this.protocol.attributes.permissions || {};
    },
    addingStepsLocked() {
      return (!this.inRepository && !this.protocol.attributes.adding_steps_allowed);
    }
  },
  data() {
    return {
      protocol: {
        attributes: {}
      },
      steps: [],
      reordering: false,
      managingSteps: false,
      stepToReload: null,
      activeDragStep: null,
      stepCollapsed: false,
      showRepositoriesModal: false,
      anchorId: null,
      elementsLoaded: 0,
      attachmentsLoaded: 0,
      loadingOverlay: false
    };
  },
  created() {
    const urlParams = new URLSearchParams(window.location.search);
    this.anchorId = urlParams.get('step_id');
    this.loadingOverlay = true;
  },
  mounted() {
    axios.get(this.protocolUrl).then((response) => {
      this.protocol = response.data.data;
      this.$nextTick(() => {
        this.refreshProtocolStatus();
        if (!this.inRepository) {
          window.addEventListener('scroll', this.initStackableHeaders, false);
          this.initStackableHeaders();
        }
      });
      this.loadSteps();
    })
  },
  beforeUnmount() {
    if (!this.inRepository) {
      window.removeEventListener('scroll', this.initStackableHeaders, false);
    }
  },
  methods: {
    setStepRelationships(step, response) {
      step.attachments = [];
      step.relationships.assets.data.forEach((asset) => {
        step.attachments.push(response.data.included.find((a) => a.id === asset.id && a.type === 'assets'));
      });

      step.elements = [];
      step.relationships.step_orderable_elements.data.forEach((element) => {
        step.elements.push(response.data.included.find((e) => e.id === element.id && e.type === 'step_orderable_elements'));
      });
    },
    loadSteps() {
      axios.get(this.urls.steps_url).then((response) => {
        const steps = response.data.data;
        steps.forEach((step) => {
          this.setStepRelationships(step, response);
        });

        this.steps = steps;
        this.loadingOverlay = false;

        if (this.anchorId) {
          this.scrollToStep();
        }
      });
    },
    scrollToStep() {
      this.$nextTick(() => {
        if (this.anchorId) {
          const step = this.$refs.steps.find((child) => child.step?.id === this.anchorId);
          if (step) {
            step.$refs.stepContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }
          this.anchorId = null;
        }
      });
    },
    getHeader() {
      return this.$refs.header;
    },
    reloadStep(step) {
      this.stepToReload = step;
    },
    deleteSteps() {
      axios.post(this.urls.delete_steps_url).then(() => {
        this.steps = [];
        this.refreshProtocolStatus();
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    archiveSteps() {
      axios.post(this.urls.archive_steps_url).then(() => {
        this.steps = [];
        this.refreshProtocolStatus();
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    addSteps(steps) {
      this.steps.push(...steps);
      this.refreshProtocolStatus();
    },
    refreshProtocolStatus() {
      if (this.inRepository) return;
      // legacy method from app/assets/javascripts/my_modules/protocols.js
      refreshProtocolStatusBar();

      // Update protocol options drowpdown for linked tasks
      this.refreshProtocolDropdownOptions();
    },
    refreshProtocolDropdownOptions() {
      if (!this.linked && this.inRepository) return;

      axios.get(this.protocolUrl).then((response) => {
        this.protocol.attributes.urls = response.data.data.attributes.urls;
      });
    },
    updateProtocol(attributes) {
      this.protocol.attributes = attributes;
    },
    updateName(newName) {
      this.protocol.attributes.name = newName;
      axios.patch(this.urls.update_protocol_name_url, { protocol: { name: newName } }).then(() => {
        this.refreshProtocolStatus();
      });
    },
    updateDescription(protocol) {
      this.protocol.attributes = protocol.attributes;
      this.refreshProtocolStatus();
    },
    addStep(position) {
      axios.post(this.urls.add_step_url, { position }).then((response) => {
        const step = response.data.data;
        step.newStep = true;

        this.setStepRelationships(step, response);
        this.updateStepsPosition(step);

        // scroll to bottom if step was appended at the end
        if (position === this.steps.length - 1) {
          this.$nextTick(() => this.scrollToBottom());
        }
        this.refreshProtocolStatus();
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response?.data?.error ? Object.values(error.response.data.error).join(', ') : I18n.t('errors.general'), 'danger');
      });
    },
    updateStepsPosition(step, action = 'add', old_position = 0) {
      const position = step.attributes.position || old_position;
      if (action === 'delete' || action === 'archive') {
        this.steps.splice(position, 1);
      }
      const unordered_steps = this.steps.map((s) => {
        if (s.attributes.position >= position) {
          if (action === 'add') {
            s.attributes.position += 1;
          } else {
            s.attributes.position -= 1;
          }
        }
        return s;
      });
      if (action === 'add') {
        unordered_steps.push(step);
      }
      this.reorderSteps(unordered_steps);
    },
    updateStep(attributes) {
      this.steps[attributes.position].attributes = {
        ...this.steps[attributes.position].attributes,
        ...attributes
      };
      this.refreshProtocolStatus();
    },
    toggleStepLock(step) {
      const url = step.attributes.locked ? step.attributes.urls.unlock_url : step.attributes.urls.lock_url;
      axios.post(url).then((response) => {
        const updatedStep = response.data.data;
        this.updateStep(updatedStep.attributes);
        this.reloadStep(parseInt(updatedStep.id, 10));
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    toggleLockAllSteps(locked) {
      const url = locked ? this.protocol.attributes.urls.lock_all_steps_url : this.protocol.attributes.urls.unlock_all_steps_url;
      axios.post(url).then(() => {
        this.loadSteps();
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    toggleDescriptionLock() {
      const locked = !this.protocol.attributes.description_locked;
      axios.post(this.protocol.attributes.urls.update_description_locked_url, { protocol: { description_locked: locked } }).then(() => {
        this.protocol.attributes.description_locked = locked;
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    reorderSteps(steps) {
      this.steps = steps.sort((a, b) => a.attributes.position - b.attributes.position);
      this.refreshProtocolStatus();
    },
    updateStepOrder(orderedSteps) {
      orderedSteps.forEach((step, position) => {
        const index = this.steps.findIndex((e) => e.id === step.id);
        this.steps[index].attributes.position = position;
      });

      const stepPositions = {
        step_positions: this.steps.map(
          (step) => [step.id, step.attributes.position]
        )
      };

      axios.post(this.protocol.attributes.urls.reorder_steps_url, stepPositions).then(() => {
        this.reorderSteps(this.steps);
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    startStepReorder() {
      this.reordering = true;
    },
    closeStepReorderModal() {
      this.reordering = false;
    },
    scrollToBottom() {
      window.scrollTo(0, document.body.scrollHeight);
    },
    scrollTop() {
      window.scrollTo(0, 0);
      setTimeout(() => {
        $('.my_module-name .view-mode').trigger('click');
        $('.my_module-name .input-field').focus();
      }, 300);
    },
    dragEnter(id) {
      this.activeDragStep = id;
    },
    uploadFilesToStep(file, stepId) {
      this.$refs.steps.find((child) => child.step?.id == stepId).uploadFiles(file);
    },
    firstObjectInViewport() {
      const step = $('.step-container:not(.locked)').toArray().find((element) => {
        const { top, bottom } = element.getBoundingClientRect();
        return bottom > 0 && top < window.innerHeight;
      });
      return step ? step.dataset.id : null;
    }
  }
};
</script>
