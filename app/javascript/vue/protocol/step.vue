<template>
  <div ref="stepContainer" class="step-container pr-8"
       :id="`stepContainer${step.id}`"
       @drop.prevent="dropFile"
       @dragenter.prevent="dragEnter($event)"
       @dragover.prevent
       :data-id="step.id"
       :class="{ 'draging-file': dragingFile, 'editing-name': editingName, 'locked': !urls.update_url, 'pointer-events-none': addingContent }"
       :data-e2e="`e2e-CO-protocol-step${step.id}`"
  >
    <div class="drop-message" @dragleave.prevent="!showFileModal ? dragingFile = false : null">
      {{ i18n.t('protocols.steps.drop_message', { position: step.attributes.position + 1 }) }}
      <StorageUsage v-if="showStorageUsage()" :parent="step"/>
    </div>
    <div class="step-header">
      <div class="step-element-header" :class="{ 'no-hover': !urls.update_url }">
        <div class="flex items-center gap-4 py-0.5 border-0 border-y border-transparent border-solid">
          <a ref="toggleElement" class="step-collapse-link hover:no-underline focus:no-underline"
            :href="'#stepBody' + step.id"
            data-toggle="collapse"
            data-remote="true"
            @click="toggleCollapsed"
            :data-e2e="`e2e-BT-protocol-step${step.id}-toggleCollapsed`">
              <span class="sn-icon sn-icon-right "></span>
          </a>
          <div v-if="!inRepository" class="step-complete-container" :class="{ 'step-element--locked': !urls.state_url }">
            <div :class="`step-state ${step.attributes.completed ? 'completed' : ''}`"
                 @click="changeState"
                 @keyup.enter="changeState"
                 tabindex="0"
                 :title="step.attributes.completed ? i18n.t('protocols.steps.status.uncomplete') : i18n.t('protocols.steps.status.complete')"
                 :data-e2e="`e2e-BT-protocol-step${step.id}-toggleCompleted`"
            ></div>
          </div>
          <div class="step-position leading-5" :data-e2e="`e2e-TX-protocol-step${step.id}-position`">
            {{ step.attributes.position + 1 }}.
          </div>
        </div>
        <div class="step-name-container basis-[calc(100%_-_100px)]" :class="{'step-element--locked': !urls.update_url}">
          <InlineEdit
            :value="step.attributes.name"
            :class="{ 'step-element--locked': !urls.update_url }"
            :characterLimit="255"
            :allowBlank="false"
            :attributeName="`${i18n.t('Step')} ${i18n.t('name')}`"
            :autofocus="editingName"
            :singleLine="false"
            :timestamp="i18n.t('protocols.steps.timestamp', { date: step.attributes.created_at, user: step.attributes.created_by })"
            :placeholder="i18n.t('protocols.steps.placeholder')"
            :defaultValue="i18n.t('protocols.steps.default_name')"
            @editingEnabled="editingName = true"
            @editingDisabled="editingName = false"
            :editOnload="step.newStep == true"
            :dataE2e="`protocol-step${step.id}-title`"
            @update="updateName"
          />
        </div>
      </div>
      <div class="elements-actions-container mt-[-5px]">
        <input type="file" class="hidden" ref="fileSelector" @change="loadFromComputer" multiple />

        <MenuDropdown
          :listItems="this.insertMenu"
          :btnText="i18n.t('protocols.steps.insert.button')"
          :position="'right'"
          :caret="true"
          :dataE2e="`e2e-DD-protocol-step${step.id}-insertContent`"
          @create:custom_well_plate="openCustomWellPlateModal"
          @create:table="(...args) => this.createElement('table', ...args)"
          @create:checklist="createElement('checklist')"
          @create:text="createElement('text')"
          @create:form="openFormSelectModal = true"
          @create:file="openLoadFromComputer"
          @create:wopi_file="openWopiFileModal"
          @create:ove_file="openOVEditor"
          @create:marvinjs_file="openMarvinJsModal($refs.marvinJsButton)"
        ></MenuDropdown>
        <span
          class="new-marvinjs-upload-button hidden"
          :data-object-id="step.id"
          ref="marvinJsButton"
          :data-marvin-url="step.attributes.marvinjs_context?.marvin_js_asset_url"
          :data-object-type="step.attributes.type"
          tabindex="0"
        ></span> <!-- Hidden element to support legacy code -->
        <template v-if="!inRepository">
          <template v-if="step.attributes.results.length == 0">
            <button ref="linkButton" v-if="urls.update_url" :title="i18n.t('protocols.steps.link_results')" class="btn btn-light icon-btn" @click="this.openLinkResultsModal = true">
              <i class="sn-icon sn-icon-results"></i>
            </button>
          </template>
          <GeneralDropdown v-else ref="linkedResultsDropdown"  position="right">
            <template v-slot:field>
              <button ref="linkButton" class="btn btn-light icon-btn" :title="i18n.t('protocols.steps.linked_results')">
                <i class="sn-icon sn-icon-results"></i>
                <span class="absolute top-1 right-1 h-4 min-w-4 bg-sn-science-blue text-white flex items-center justify-center rounded-full text-[10px]">
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
              <template v-if="urls.update_url">
                <hr class="my-0">
                <div class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer text-sn-blue"
                    @click="this.openLinkResultsModal = true; $refs.linkedResultsDropdown.closeMenu()">
                  {{ i18n.t('protocols.steps.manage_links') }}
                </div>
              </template>
            </template>
          </GeneralDropdown>
        </template>
        <a href=" #"
           v-if="!inRepository"
           ref="comments"
           class="open-comments-sidebar btn icon-btn btn-light"
           data-turbolinks="false"
           data-object-type="Step"
           @click="openCommentsSidebar"
           :data-object-id="step.id">
          <i class="sn-icon sn-icon-comments"></i>
          <span class="comments-counter"
                :id="`comment-count-${step.id}`"
                :class="{'unseen': step.attributes.unseen_comments, 'hidden': !step.attributes.comments_count}"
          >
            {{ step.attributes.comments_count }}
          </span>
        </a>
        <MenuDropdown
          :listItems="this.actionsMenu"
          :btnClasses="'btn btn-light icon-btn'"
          :position="'right'"
          :btnIcon="'sn-icon sn-icon-more-hori'"
          :dataE2e="`e2e-DD-protocol-step${step.id}-options`"
          @reorder="openReorderModal"
          @duplicate="duplicateStep"
          @delete="showDeleteModal"
        ></MenuDropdown>
      </div>
    </div>
    <div class="collapse in" :id="'stepBody' + step.id">
      <div class="step-elements">
        <component
          v-for="(element, index) in orderedElements"
          :is="elements[index].attributes.orderable_type"
          :key="element.id"
          class="step-element"
          :element.sync="elements[index]"
          :inRepository="inRepository"
          :reorderElementUrl="elements.length > 1 ? urls.reorder_elements_url : ''"
          :assignableMyModuleId="assignableMyModuleId"
          :isNew="element.isNew"
          :dataE2e="`protocol-step${step.id}`"
          @component:adding-content="($event) => addingContent = $event"
          @component:delete="deleteElement"
          @update="updateElement"
          @reorder="openReorderModal"
          @component:insert="insertElement"
          @moved="moveElement"
        />
        <Attachments v-if="attachments.length"
                    :parent="step"
                    :attachments="attachments"
                    :attachmentsReady="attachmentsReady"
                    :dataE2e="`protocol-step${step.id}`"
                    @attachments:openFileModal="showFileModal = true"
                    @attachment:deleted="attachmentDeleted"
                    @attachment:update="updateAttachment"
                    @attachment:uploaded="loadAttachments"
                    @attachment:changed="reloadAttachment"
                    @attachments:order="changeAttachmentsOrder"
                    @attachment:moved="moveAttachment"
                    @attachments:viewMode="changeAttachmentsViewMode"
                    @attachment:viewMode="updateAttachmentViewMode"/>
      </div>
      <ContentToolbar
        v-if="orderedElements.length > 2 && insertMenu.length > 0"
        :insertMenu="insertMenu"
        @create:custom_well_plate="openCustomWellPlateModal"
        @create:table="(...args) => this.createElement('table', ...args)"
        @create:checklist="createElement('checklist')"
        @create:text="createElement('text')"
        @create:form="openFormSelectModal = true"
        @create:file="openLoadFromComputer"
        @create:wopi_file="openWopiFileModal"
        @create:ove_file="openOVEditor"
        @create:marvinjs_file="openMarvinJsModal($refs.marvinJsButton)"
      ></ContentToolbar>
    </div>

    <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
    <ReorderableItemsModal v-if="reordering"
      :title="i18n.t('protocols.steps.modals.reorder_elements.title', { step_position: step.attributes.position + 1 })"
      :items="reorderableElements"
      :dataE2e="`protocol-step${step.id}-reorder`"
      @reorder="updateElementOrder"
      @close="closeReorderModal"
    />

    <CustomWellPlateModal v-if="customWellPlate"
      @cancel="closeCustomWellPlateModal"
      @create:table="(...args) => this.createElement('table', ...args)"
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
  const ICON_MAP = {
    'Checklist': 'fa-list-ul',
    'StepText': 'fa-font',
    'StepTable': 'fa-table'
  }

  import InlineEdit from '../shared/inline_edit.vue'
  import StepTable from '../shared/content/table.vue'
  import StepText from '../shared/content/text.vue'
  import Checklist from '../shared/content/checklist.vue'
  import FormResponse from '../shared/content/form_response.vue'
  import deleteStepModal from './modals/delete_step.vue'
  import LinkResultsModal from './modals/link_results.vue'
  import Attachments from '../shared/content/attachments.vue'
  import ReorderableItemsModal from '../shared/reorderable_items_modal.vue'
  import MenuDropdown from '../shared/menu_dropdown.vue'
  import GeneralDropdown from '../shared/general_dropdown.vue'
  import ContentToolbar from '../shared/content/content_toolbar.vue'
  import CustomWellPlateModal from '../shared/content/modal/custom_well_plate_modal.vue'

  import UtilsMixin from '../mixins/utils.js'
  import AttachmentsMixin from '../shared/content/mixins/attachments.js'
  import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js'
  import SelectFormModal from '../shared/content/modal/form_select.vue'
  import OveMixin from '../shared/content/attachments/mixins/ove.js'
  import StorageUsage from '../shared/content/attachments/storage_usage.vue'
  import axios from '../../packs/custom_axios';

  import {
    my_module_results_path,
  } from '../../routes.js';

  export default {
    name: 'StepContainer',
    props: {
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
      userSettingsUrl: {
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
        elements: [],
        attachments: [],
        attachmentsReady: false,
        confirmingDelete: false,
        addingContent: false,
        showFileModal: false,
        showCommentsSidebar: false,
        dragingFile: false,
        reordering: false,
        isCollapsed: false,
        editingName: false,
        inlineEditError: null,
        customWellPlate: false,
        openFormSelectModal: false,
        openLinkResultsModal: false,
        wellPlateOptions: [
          { text: I18n.t('protocols.steps.insert.well_plate_options.custom'),
            emit: 'create:custom_well_plate',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-customWellPlate` },
          { text: I18n.t('protocols.steps.insert.well_plate_options.32_x_48'),
            emit: 'create:table',
            params: [32, 48],
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellPlate-32` },
          { text: I18n.t('protocols.steps.insert.well_plate_options.16_x_24'),
            emit: 'create:table',
            params: [16, 24],
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellPlate-16` },
          { text: I18n.t('protocols.steps.insert.well_plate_options.8_x_12'),
            emit: 'create:table',
            params: [8, 12],
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellPlate-8` },
          { text: I18n.t('protocols.steps.insert.well_plate_options.6_x_8'),
            emit: 'create:table',
            params: [6, 8],
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellPlate-6` },
          { text: I18n.t('protocols.steps.insert.well_plate_options.4_x_6'),
            emit: 'create:table',
            params: [4, 6],
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellPlate-4` },
          { text: I18n.t('protocols.steps.insert.well_plate_options.3_x_4'),
            emit: 'create:table',
            params: [3, 4],
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellPlate-3` },
          { text: I18n.t('protocols.steps.insert.well_plate_options.2_x_3'),
            emit: 'create:table',
            params: [2, 3],
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellPlate-2` }
        ]
      }
    },
    mixins: [UtilsMixin, AttachmentsMixin, WopiFileModal, OveMixin],
    components: {
      InlineEdit,
      StepTable,
      StepText,
      Checklist,
      deleteStepModal,
      Attachments,
      StorageUsage,
      ReorderableItemsModal,
      MenuDropdown,
      ContentToolbar,
      CustomWellPlateModal,
      SelectFormModal,
      FormResponse,
      LinkResultsModal,
      GeneralDropdown
    },
    created() {
      this.loadAttachments();
      this.loadElements();
    },
    watch: {
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
      },
      step: {
        handler(newVal) {
          if (this.isCollapsed !== newVal.attributes.collapsed) {
            this.toggleCollapsed();
          }
        },
        deep: true
      }
    },
    mounted() {
      this.$nextTick(() => {
        const stepId = `#stepBody${this.step.id}`;
        this.isCollapsed = this.step.attributes.collapsed;
        if (this.isCollapsed) {
          $(stepId).collapse('hide');
        } else {
          $(stepId).collapse('show');
        }
        this.$emit('step:collapsed');
      });
      $(this.$refs.comments).data('closeCallback', this.closeCommentsSidebar);
      $(this.$refs.comments).data('openCallback', this.closeCommentsSidebar);
      $(this.$refs.actionsDropdownButton).on('shown.bs.dropdown hidden.bs.dropdown', () => {
        this.handleDropdownPosition(this.$refs.actionsDropdownButton, this.$refs.actionsDropdown)
      });
      $(this.$refs.elementsDropdownButton).on('shown.bs.dropdown hidden.bs.dropdown', () => {
        this.handleDropdownPosition(this.$refs.elementsDropdownButton, this.$refs.elementsDropdown)
      });

      window.initTooltip(this.$refs.linkButton);
    },
    beforeUnmount() {
      window.destroyTooltip(this.$refs.linkButton);
    },
    computed: {
      reorderableElements() {
        return this.orderedElements.map((e) => { return { id: e.id, attributes: e.attributes.orderable } })
      },
      orderedElements() {
        return this.elements.sort((a, b) => a.attributes.position - b.attributes.position);
      },
      urls() {
        return this.step.attributes.urls || {}
      },
      filesMenu() {
        let menu = [];
        if (this.urls.upload_attachment_url) {
          menu = menu.concat([{
            text: this.i18n.t('protocols.steps.insert.add_file'),
            emit: 'create:file',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertAttachment-file`
          }]);
        }
        if (this.step.attributes.wopi_enabled) {
          menu = menu.concat([{
            text: this.i18n.t('assets.create_wopi_file.button_text'),
            emit: 'create:wopi_file',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertAttachment-wopi`
          }]);
        }
        if (this.step.attributes.open_vector_editor_context.new_sequence_asset_url) {
          menu = menu.concat([{
            text: this.i18n.t('open_vector_editor.new_sequence_file'),
            emit: 'create:ove_file',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertAttachment-sequence`
          }]);
        }
        if (this.step.attributes.marvinjs_enabled) {
          menu = menu.concat([{
            text: this.i18n.t('marvinjs.new_button'),
            emit: 'create:marvinjs_file',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-insertAttachment-chemicalDrawing`
          }]);
        }
        return menu;
      },
      insertMenu() {
        let menu = [];
        if (this.urls.update_url) {
          menu = menu.concat([{
                    text: this.i18n.t('protocols.steps.insert.text'),
                    icon: 'sn-icon sn-icon-result-text',
                    emit: 'create:text',
                    data_e2e: `e2e-BT-protocol-step${this.step.id}-insertText`
                  },{
                    text: this.i18n.t('protocols.steps.insert.attachment'),
                    submenu: this.filesMenu,
                    position: 'left',
                    icon: 'sn-icon sn-icon-file',
                    data_e2e: `e2e-BT-protocol-step${this.step.id}-insertAttachment`
                  },{
                    text: this.i18n.t('protocols.steps.insert.table'),
                    icon: 'sn-icon sn-icon-tables',
                    emit: 'create:table',
                    data_e2e: `e2e-BT-protocol-step${this.step.id}-insertTable`
                  },{
                    text: this.i18n.t('protocols.steps.insert.well_plate'),
                    submenu: this.wellPlateOptions,
                    icon: 'sn-icon sn-icon-tables',
                    position: 'left',
                    data_e2e: `e2e-BT-protocol-step${this.step.id}-insertWellplate`
                  },{
                    text: this.i18n.t('protocols.steps.insert.checklist'),
                    emit: 'create:checklist',
                    icon: 'sn-icon sn-icon-checkllist',
                    data_e2e: `e2e-BT-protocol-step${this.step.id}-insertChecklist`
                  }]);
        }

        if (this.urls.create_form_response_url) {
          menu = menu.concat([{
                   text: this.i18n.t('protocols.steps.insert.form'),
                   emit: 'create:form',
                   icon: 'sn-icon sn-icon-forms',
                   data_e2e: `e2e-BT-protocol-step${this.step.id}-insertForm`
                 }]);
        }

        return menu;
      },
      actionsMenu() {
        let menu = [];
        if (this.urls.reorder_elements_url && this.elements.length > 1) {
          menu = menu.concat([{
            text: this.i18n.t('protocols.steps.options_dropdown.rearrange'),
            emit: 'reorder',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-stepOptions-rearrange`
          }]);
        }
        if (this.urls.duplicate_step_url) {
          menu = menu.concat([{
            text: this.i18n.t('protocols.steps.options_dropdown.duplicate'),
            emit: 'duplicate',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-stepOptions-duplicate`
          }]);
        }
        if (this.urls.delete_url) {
          menu = menu.concat([{
            text: this.i18n.t('protocols.steps.options_dropdown.delete'),
            emit: 'delete',
            data_e2e: `e2e-BT-protocol-step${this.step.id}-stepOptions-delete`
          }]);
        }
        return menu;
      }
    },
    methods: {
      dragEnter(e) {
        if (this.showFileModal || !this.urls.upload_attachment_url) return;

        // Detect if dragged element is a file
        // https://stackoverflow.com/a/8494918
        let dt = e.dataTransfer;
        if (dt.types && (dt.types.indexOf ? dt.types.indexOf('Files') != -1 : dt.types.contains('Files'))) {
          this.dragingFile = true;
          this.$emit('step:drag_enter', this.step.id);
        }
      },
      loadAttachments() {
        this.attachmentsReady = false

        $.get(this.urls.attachments_url, (result) => {
          this.attachments = result.data
          this.$emit('step:attachments:loaded');
          if (this.attachments.findIndex((e) => e.attributes.attached === false) >= 0) {
            setTimeout(() => {
              this.loadAttachments()
            }, 10000)
          } else {
            this.attachmentsReady = true
          }
        });
        this.showFileModal = false;
      },
      reloadAttachment(attachmentId) {
        const index = this.attachments.findIndex(attachment => attachment.id === attachmentId);
        const attachmentUrl = this.attachments[index].attributes.urls.asset_show

        axios.get(attachmentUrl)
          .then((response) => {
            const updatedAttachment = response.data.data;
            const index = this.attachments.findIndex(attachment => attachment.id === attachmentId);

            if (index !== -1) {
              this.attachments[index] = updatedAttachment;
            }
          })
          .catch((error) => {
            console.error("Failed to reload attachment:", error);
          });

        this.showFileModal = false;
      },
      loadElements() {
        $.get(this.urls.elements_url, (result) => {
          this.elements = result.data
          this.$emit('step:elements:loaded');
        });
      },
      showStorageUsage() {
        return (this.elements.length || this.attachments.length) && !this.isCollapsed && this.step.attributes.storage_limit;
      },
      toggleCollapsed() {
        this.isCollapsed = !this.isCollapsed;

        this.step.attributes.collapsed = this.isCollapsed;

        const settings = {
          key: 'task_step_states',
          data: { [this.step.id]: this.isCollapsed }
        };

        this.$emit('step:collapsed');
        axios.put(this.userSettingsUrl, { settings: [settings] });
      },
      showDeleteModal() {
        this.confirmingDelete = true;
      },
      closeDeleteModal() {
        this.confirmingDelete = false;
      },
      deleteStep() {
        $.ajax({
          url: this.urls.delete_url,
          type: 'DELETE',
          success: (result) => {
            this.$emit(
              'step:delete',
              result.data,
              'delete'
            );
          }
        });
      },
      changeState() {
        if (!this.urls.state_url) return;

        this.step.attributes.completed = !this.step.attributes.completed;
        this.$emit('step:update', {
          completed: this.step.attributes.completed,
          position: this.step.attributes.position
        });
        $.post(this.urls.state_url, {completed: this.step.attributes.completed}).fail(() => {
          this.step.attributes.completed = !this.step.attributes.completed;
          this.$emit('step:update', {
            completed: this.step.attributes.completed,
            position: this.step.attributes.position
          });
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        })
      },
      deleteElement(position) {
        this.elements.splice(position, 1)
        let unorderedElements = this.elements.map( e => {
          if (e.attributes.position >= position) {
            e.attributes.position -= 1;
          }
          return e;
        })
        this.$emit('stepUpdated')
      },
      updateElement(element, skipRequest=false, callback) {
        let index = this.elements.findIndex((e) => e.id === element.id);

        if (!this.elements[index]) return;

        this.elements[index].isNew = false;

        if (skipRequest || !element.attributes.orderable?.urls?.update_url) {
          this.elements[index].attributes.orderable = element.attributes.orderable;
          this.$emit('stepUpdated');
        } else {
          $.ajax({
            url: element.attributes.orderable.urls.update_url,
            method: 'PUT',
            data: element.attributes.orderable,
            success: (result) => {
              this.elements[index].attributes.orderable = result.data.attributes;
              this.$emit('stepUpdated');

              // optional callback after successful update
              if(typeof callback === 'function') {
                callback();
              }
            }
          }).fail(() => {
            HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
          })
        }
      },
      updateElementOrder(orderedElements) {
        orderedElements.forEach((element, position) => {
          let index = this.elements.findIndex((e) => e.id === element.id);
          this.elements[index].attributes.position = position;
        });


        let elementPositions =
          {
            step_orderable_element_positions: this.elements.map(
              (element) => [element.id, element.attributes.position]
            )
          };

        $.ajax({
          type: "POST",
          url: this.urls.reorder_elements_url,
          data: JSON.stringify(elementPositions),
          contentType: "application/json",
          dataType: "json",
          error: (() => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')),
          success: (() => this.$emit('stepUpdated'))
        });
      },
      updateName(newName) {
        $.ajax({
          url: this.urls.update_url,
          type: 'PATCH',
          data: {step: {name: newName}},
          success: (result) => {
            this.$emit('step:update', {
              name: result.data.attributes.name,
              position: this.step.attributes.position
            })
          },
          error: (data) => {
            HelperModule.flashAlertMsg(data.responseJSON.errors ? Object.values(data.responseJSON.errors).join(', ') : I18n.t('errors.general'), 'danger');
          }
        });
      },
      createElement(elementType, tableDimensions = null, name = '', formId = null) {
        let plateTemplate = tableDimensions != null;
        tableDimensions ||= [5, 5];
        $.post(this.urls[`create_${elementType}_url`], { tableDimensions: tableDimensions, plateTemplate: plateTemplate, name: name, form_id: formId }, (result) => {
          result.data.isNew = true;
          this.elements.push(result.data)

          if (this.isCollapsed) {
            this.$refs.toggleElement.click();
          }
          this.$emit('stepUpdated')
        }).fail(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        }).done(() => {
          this.$parent.$nextTick(() => {
            const children = this.$refs.stepContainer.querySelectorAll(".step-element");
            const lastChild = children[children.length - 1];

            lastChild.scrollIntoView(false)
            window.scrollBy({
              top: 200,
              behavior: 'smooth'
            });
          })
        });
      },
      openCustomWellPlateModal() {
        this.customWellPlate = true;
      },
      closeCustomWellPlateModal() {
        this.customWellPlate = false;
      },
      openCommentsSidebar() {
        $('.comments-sidebar .close-btn').click();
        this.showCommentsSidebar = true
      },
      attachmentDeleted(id) {
        this.attachments = this.attachments.filter((a) => a.id !== id );
        this.$emit('stepUpdated');
      },
      updateAttachment(attachment) {
        const index = this.attachments.findIndex(a => a.id === attachment.id);
        if (index !== -1) {
          this.attachments[index] = attachment;
          this.$emit('stepUpdated');
        }
      },
      closeCommentsSidebar() {
        this.showCommentsSidebar = false
      },
      openReorderModal() {
        this.reordering = true;
      },
      closeReorderModal() {
        this.reordering = false;
      },
      handleDropdownPosition(refButton, refDropdown) {
        refButton.classList.toggle("dropup", !this.isInViewport(refDropdown));
      },
      isInViewport(el) {
          let rect = el.getBoundingClientRect();

          return (
              rect.top >= 0 &&
              rect.left >= 0 &&
              rect.bottom <= (window.innerHeight || $(window).height()) &&
              rect.right <= (window.innerWidth || $(window).width())
          );
      },
      insertElement(element) {
        let position = element.attributes.position;
        this.elements = this.elements.map( s => {
          if (s.attributes.position >= position) {
              s.attributes.position += 1;
          }
          return s;
        })
        this.elements.push(element);
        this.$emit('stepUpdated');
      },
      moveElement(position, target_id) {
        this.elements.splice(position, 1)
        let unorderedElements = this.elements.map( e => {
          if (e.attributes.position >= position) {
            e.attributes.position -= 1;
          }
          return e;
        })
        this.$emit('stepUpdated')
        this.$emit('step:move_element', target_id)
      },
      moveAttachment(id, target_id) {
        this.attachments = this.attachments.filter((a) => a.id !== id );
        this.$emit('stepUpdated')
        this.$emit('step:move_attachment', target_id)
      },
      duplicateStep() {
        $.post(this.urls.duplicate_step_url, (result) => {
          this.$emit('step:insert', result.data);
          HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.step_duplicated'), 'success');
        }).fail(() => {
          HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.step_duplication_failed'), 'danger');
        });
      },
      updateLinkedResults(results) {
        window.destroyTooltip(this.$refs.linkButton);

        this.$emit('step:update', {
          results: results,
          position: this.step.attributes.position
        });

        this.$nextTick(() => window.initTooltip(this.$refs.linkButton));
      },
      resultUrl(result_id, archived) {
        return my_module_results_path({my_module_id: this.step.attributes.my_module_id, result_id: result_id, view_mode: (archived ? 'archived' : 'active') });
      },
    }
  }
</script>
