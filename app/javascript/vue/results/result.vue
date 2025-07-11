<template>
  <div ref="resultContainer"
       class="result-wrapper p-4 mb-4 rounded pr-8 relative"
       @drop.prevent="dropFile"
       @dragenter.prevent="dragEnter($event)"
       @dragover.prevent
       :data-id="result.id"
       :class="{ 'bg-sn-super-light-blue': dragingFile, 'bg-white': !dragingFile, 'locked': locked, 'pointer-events-none': addingContent }"
  >
    <div class="text-xl items-center flex flex-col text-sn-blue h-full justify-center left-0 absolute top-0 w-full"
         v-if="dragingFile"
         @dragleave.prevent="dragingFile = false">
      {{ i18n.t('my_modules.results.drop_message', { name: result.attributes.name }) }}
      <StorageUsage v-if="showStorageUsage()" :parent="result"/>
    </div>
    <div :class="{ 'opacity-0 pointer-events-none': dragingFile }">
      <div class="result-header flex justify-between">
        <div class="result-head-left flex items-start flex-grow gap-4">
          <a ref="toggleElement" class="result-collapse-link hover:no-underline focus:no-underline py-0.5 border-0 border-y border-transparent border-solid text-sn-black"
              :href="'#resultBody' + result.id"
              data-toggle="collapse"
              data-remote="true"
              @click="toggleCollapsed">
            <span class="sn-icon sn-icon-right "></span>
          </a>
          <InlineEdit
            :value="result.attributes.name"
            class="flex-grow font-bold text-base"
            :class="{ 'pointer-events-none': !urls.update_url }"
            :singleLine="false"
            :characterLimit="255"
            :allowBlank="false"
            :attributeName="`${i18n.t('Result')} ${i18n.t('name')}`"
            :autofocus="editingName"
            :placeholder="i18n.t('my_modules.results.placeholder')"
            :defaultValue="i18n.t('my_modules.results.default_name')"
            :timestamp="i18n.t('protocols.steps.timestamp', {date: result.attributes.created_at, user: result.attributes.created_by })"
            @editingEnabled="editingName = true"
            @editingDisabled="editingName = false"
            :editOnload="result.newResult == true"
            @update="updateName"
          />
        </div>
        <div class="result-head-right flex elements-actions-container">
          <input type="file" class="hidden" ref="fileSelector" @change="loadFromComputer" multiple />
          <MenuDropdown
            :listItems="this.insertMenu"
            :btnText="i18n.t('my_modules.results.insert.button')"
            :position="'right'"
            :caret="true"
            @create:custom_well_plate="openCustomWellPlateModal"
            @create:table="(...args) => this.createElement('table', ...args)"
            @create:checklist="createElement('checklist')"
            @create:text="createElement('text')"
            @create:file="openLoadFromComputer"
            @create:wopi_file="openWopiFileModal"
            @create:ove_file="openOVEditor"
            @create:marvinjs_file="openMarvinJsModal($refs.marvinJsButton)"
          ></MenuDropdown>
          <span
            class="new-marvinjs-upload-button hidden"
            :data-object-id="result.id"
            ref="marvinJsButton"
            :data-marvin-url="result.attributes.marvinjs_context?.marvin_js_asset_url"
            :data-object-type="result.attributes.type"
            tabindex="0"
          ></span> <!-- Hidden element to support legacy code -->
          <tempplate v-if="result.attributes.steps.length == 0">
            <button v-if="urls.update_url" ref="linkButton" :title="i18n.t('my_modules.results.link_steps')" class="btn btn-light icon-btn" @click="this.openLinkStepsModal = true">
              {{ i18n.t('my_modules.results.link_to_step') }}
            </button>
          </tempplate>
          <GeneralDropdown v-else ref="linkedStepsDropdown"  position="right">
            <template v-slot:field>
              <button ref="linkButton" class="btn btn-light icon-btn" :title="i18n.t('my_modules.results.linked_steps')">
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
                >
                  {{ step.name }}
                </a>
              </div>
              <template v-if="urls.update_url">
                <hr class="my-0">
                <div class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer text-sn-blue"
                    @click="this.openLinkStepsModal = true; $refs.linkedStepsDropdown.closeMenu()">
                  {{ i18n.t('protocols.steps.manage_links') }}
                </div>
              </template>
            </template>
          </GeneralDropdown>
          <a href="#"
            ref="comments"
            class="open-comments-sidebar btn icon-btn btn-light"
            data-turbolinks="false"
            data-object-type="Result"
            :data-object-id="result.id">
            <i class="sn-icon sn-icon-comments"></i>
            <span class="comments-counter" :class="{ 'hidden': !result.attributes.comments_count }"
                  :id="`comment-count-${result.id}`">
                {{ result.attributes.comments_count }}
            </span>
          </a>

          <MenuDropdown
            v-if="!locked"
            :listItems="this.actionsMenu"
            :btnClasses="'btn btn-light icon-btn'"
            :position="'right'"
            :btnIcon="'sn-icon sn-icon-more-hori'"
            @reorder="openReorderModal"
            @duplicate="duplicateResult"
            @archive="archiveResult"
            @restore="restoreResult"
            @delete="showDeleteModal"
          ></MenuDropdown>
        </div>
      </div>
      <deleteResultModal v-if="confirmingDelete" @confirm="deleteResult" @cancel="closeDeleteModal"/>

      <ReorderableItemsModal v-if="reordering"
        :title="i18n.t('my_modules.modals.reorder_results.title')"
        :items="reorderableElements"
        :dataE2e="`task-result${result.id}-reorder`"
        @reorder="updateElementOrder"
        @close="closeReorderModal"
      />
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
            @component:delete="deleteElement"
            @update="updateElement"
            @reorder="openReorderModal"
            @component:insert="insertElement"
            @moved="moveElement"
          />
        </div>
        <Attachments v-if="attachments.length"
                      :parent="result"
                      :attachments="attachments"
                      :attachmentsReady="attachmentsReady"
                      @attachments:openFileModal="showFileModal = true"
                      @attachment:deleted="attachmentDeleted"
                      @attachment:update="updateAttachment"
                      @attachment:uploaded="loadAttachments"
                      @attachment:moved="moveAttachment"
                      @attachments:order="changeAttachmentsOrder"
                      @attachments:viewMode="changeAttachmentsViewMode"
                      @attachment:viewMode="updateAttachmentViewMode"/>
        <ContentToolbar
          v-if="orderedElements.length > 2 && insertMenu.length > 0"
          :insertMenu="insertMenu"
          @create:custom_well_plate="openCustomWellPlateModal"
          @create:table="(...args) => this.createElement('table', ...args)"
          @create:text="createElement('text')"
          @create:file="openLoadFromComputer"
          @create:wopi_file="openWopiFileModal"
          @create:ove_file="openOVEditor"
          @create:marvinjs_file="openMarvinJsModal($refs.marvinJsButton)"
        ></ContentToolbar>

        <CustomWellPlateModal v-if="customWellPlate"
          @cancel="closeCustomWellPlateModal"
          @create:table="(...args) => this.createElement('table', ...args)"
        />
        <Teleport to="body">
          <LinkStepsModal
            v-if="openLinkStepsModal"
            :result="result"
            :protocolId="protocolId"
            @updateResult="updateLinkedSteps"
            @close="openLinkStepsModal = false"
          />
        </Teleport>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import ReorderableItemsModal from '../shared/reorderable_items_modal.vue';
import ResultTable from '../shared/content/table.vue';
import ResultText from '../shared/content/text.vue';
import Attachments from '../shared/content/attachments.vue';
import InlineEdit from '../shared/inline_edit.vue';
import MenuDropdown from '../shared/menu_dropdown.vue';
import GeneralDropdown from '../shared/general_dropdown.vue';
import deleteResultModal from './delete_result.vue';
import LinkStepsModal from './modals/link_steps.vue'
import ContentToolbar from '../shared/content/content_toolbar';
import CustomWellPlateModal from '../shared/content/modal/custom_well_plate_modal.vue'

import AttachmentsMixin from '../shared/content/mixins/attachments.js';
import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js';
import OveMixin from '../shared/content/attachments/mixins/ove.js';
import UtilsMixin from '../mixins/utils.js';
import StorageUsage from '../shared/content/attachments/storage_usage.vue';
import {
  protocols_my_module_path,
} from '../../routes.js';

export default {
  name: 'Results',
  props: {
    result: { type: Object, required: true },
    resultToReload: { type: Number, required: false },
    protocolId: { type: Number, required: false },
    activeDragResult: {
      required: false
    },
    userSettingsUrl: {
      required: false
    }
  },
  data() {
    return {
      reordering: false,
      elements: [],
      attachments: [],
      attachmentsReady: false,
      addingContent: false,
      showFileModal: false,
      dragingFile: false,
      customWellPlate: false,
      openLinkStepsModal: false,
      wellPlateOptions: [
        { text: I18n.t('protocols.steps.insert.well_plate_options.custom'), emit: 'create:custom_well_plate'},
        { text: I18n.t('protocols.steps.insert.well_plate_options.32_x_48'), emit: 'create:table', params: [32, 48] },
        { text: I18n.t('protocols.steps.insert.well_plate_options.16_x_24'), emit: 'create:table', params: [16, 24] },
        { text: I18n.t('protocols.steps.insert.well_plate_options.8_x_12'), emit: 'create:table', params: [8, 12] },
        { text: I18n.t('protocols.steps.insert.well_plate_options.6_x_8'), emit: 'create:table', params: [6, 8] },
        { text: I18n.t('protocols.steps.insert.well_plate_options.4_x_6'), emit: 'create:table', params: [4, 6] },
        { text: I18n.t('protocols.steps.insert.well_plate_options.3_x_4'), emit: 'create:table', params: [3, 4] },
        { text: I18n.t('protocols.steps.insert.well_plate_options.2_x_3'), emit: 'create:table', params: [2, 3] }
      ],
      editingName: false,
      confirmingDelete: false,
      isCollapsed: false
    };
  },
  mixins: [UtilsMixin, AttachmentsMixin, WopiFileModal, OveMixin],
  components: {
    ReorderableItemsModal,
    ResultTable,
    ResultText,
    Attachments,
    InlineEdit,
    MenuDropdown,
    deleteResultModal,
    StorageUsage,
    ContentToolbar,
    CustomWellPlateModal,
    LinkStepsModal,
    GeneralDropdown
  },
  watch: {
    resultToReload() {
      if (Number(this.resultToReload) === Number(this.result.id)) {
        this.loadElements();
        this.loadAttachments();
      }
    },
    activeDragResult() {
      if (this.activeDragResult !== this.result.id && this.dragingFile) {
        this.dragingFile = false;
      }
    },
    result: {
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
      const resultId = `#resultBody${this.result.id}`;
      this.isCollapsed = this.result.attributes.collapsed;
      if (this.isCollapsed) {
        $(resultId).collapse('hide');
      } else {
        $(resultId).collapse('show');
      }
      this.$emit('result:collapsed');
    });

    window.initTooltip(this.$refs.linkButton);
  },
  beforeUnmount() {
    window.destroyTooltip(this.$refs.linkButton);
  },
  computed: {
    reorderableElements() {
      return this.orderedElements.map((e) => ({ id: e.id, attributes: e.attributes.orderable }));
    },
    orderedElements() {
      return this.elements.sort((a, b) => a.attributes.position - b.attributes.position);
    },
    urls() {
      return this.result.attributes.urls || {};
    },
    locked() {
      return !(this.urls.restore_url || this.urls.archive_url || this.urls.delete_url || this.urls.update_url);
    },
    filesMenu() {
      let menu = [];
      if (this.urls.upload_attachment_url) {
        menu = menu.concat([{
          text: this.i18n.t('my_modules.results.insert.add_file'),
          emit: 'create:file'
        }]);
      }
      if (this.result.attributes.wopi_enabled) {
        menu = menu.concat([{
          text: this.i18n.t('assets.create_wopi_file.button_text'),
          emit: 'create:wopi_file'
        }]);
      }
      if (this.result.attributes.open_vector_editor_context.new_sequence_asset_url) {
        menu = menu.concat([{
          text: this.i18n.t('open_vector_editor.new_sequence_file'),
          emit: 'create:ove_file'
        }]);
      }
      if (this.result.attributes.marvinjs_enabled) {
        menu = menu.concat([{
          text: this.i18n.t('marvinjs.new_button'),
          emit: 'create:marvinjs_file'
        }]);
      }
      return menu;
    },
    insertMenu() {
      let menu = [];
      if (this.urls.update_url) {
        menu = menu.concat([{
          text: this.i18n.t('my_modules.results.insert.text'),
          icon: 'sn-icon sn-icon-result-text',
          emit: 'create:text'
        }, {
          text: this.i18n.t('my_modules.results.insert.attachment'),
          submenu: this.filesMenu,
          icon: 'sn-icon sn-icon-file',
          position: 'left'
        }, {
          text: this.i18n.t('my_modules.results.insert.table'),
          icon: 'sn-icon sn-icon-tables',
          emit: 'create:table'
        }, {
          text: this.i18n.t('my_modules.results.insert.well_plate'),
          icon: 'sn-icon sn-icon-tables',
          submenu: this.wellPlateOptions,
          position: 'left'
        }]);
      }

      return menu;
    },
    actionsMenu() {
      let menu = [];
      if (this.urls.reorder_elements_url && this.elements.length > 1) {
        menu = menu.concat([{
          text: this.i18n.t('my_modules.results.actions.rearrange'),
          emit: 'reorder'
        }]);
      }
      if (this.urls.duplicate_url && !this.result.attributes.archived) {
        menu = menu.concat([{
          text: this.i18n.t('my_modules.results.actions.duplicate'),
          emit: 'duplicate'
        }]);
      }
      if (this.urls.archive_url) {
        menu = menu.concat([{
          text: this.i18n.t('my_modules.results.actions.archive'),
          emit: 'archive'
        }]);
      }
      if (this.urls.restore_url) {
        menu = menu.concat([{
          text: this.i18n.t('my_modules.results.actions.restore'),
          emit: 'restore'
        }]);
      }
      if (this.urls.delete_url) {
        menu = menu.concat([{
          text: this.i18n.t('my_modules.results.actions.delete'),
          emit: 'delete'
        }]);
      }
      return menu;
    }
  },
  created() {
    this.loadAttachments();
    this.loadElements();
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
      this.result.attributes.collapsed = this.isCollapsed;

      const settings = {
        key: 'result_states',
        data: { [this.result.id]: this.isCollapsed }
      };

      axios.put(this.userSettingsUrl, { settings: [settings] });

      this.$emit('result:collapsed');
    },
    dragEnter(e) {
      if (!this.urls.upload_attachment_url) return;

      // Detect if dragged element is a file
      // https://stackoverflow.com/a/8494918
      const dt = e.dataTransfer;
      if (dt.types && (dt.types.indexOf ? dt.types.indexOf('Files') !== -1 : dt.types.contains('Files'))) {
        this.dragingFile = true;
        this.$emit('result:drag_enter', this.result.id);
      }
    },
    showStorageUsage() {
      return (this.elements.length || this.attachments.length) && !this.isCollapsed && this.result.attributes.storage_limit;
    },
    openReorderModal() {
      this.reordering = true;
    },
    closeReorderModal() {
      this.reordering = false;
    },
    updateElementOrder(orderedElements) {
      orderedElements.forEach((element, position) => {
        const index = this.elements.findIndex((e) => e.id === element.id);
        this.elements[index].attributes.position = position;
      });

      const elementPositions = {
        result_orderable_element_positions: this.elements.map(
          (element) => [element.id, element.attributes.position]
        )
      };

      axios.post(this.urls.reorder_elements_url, elementPositions, {
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json'
        }
      })
        .then(() => {
          this.$emit('resultUpdated');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
    },
    deleteElement(position) {
      this.elements.splice(position, 1);
      const unorderedElements = this.elements.map((e) => {
        if (e.attributes.position >= position) {
          e.attributes.position -= 1;
        }
        return e;
      });
      this.$emit('resultUpdated');
    },
    updateElement(element, skipRequest = false, callback) {
      const index = this.elements.findIndex((e) => e.id === element.id);
      this.elements[index].isNew = false;

      if (skipRequest) {
        this.elements[index].attributes.orderable = element.attributes.orderable;
        this.$emit('resultUpdated');
      } else {
        $.ajax({
          url: element.attributes.orderable.urls.update_url,
          method: 'PUT',
          data: element.attributes.orderable,
          success: (result) => {
            this.elements[index].attributes.orderable = result.data.attributes;
            this.$emit('resultUpdated');

            // optional callback after successful update
            if (typeof callback === 'function') {
              callback();
            }
          }
        }).fail(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
      }
    },
    insertElement(element) {
      const { position } = element.attributes;
      this.elements = this.elements.map((s) => {
        if (s.attributes.position >= position) {
          s.attributes.position += 1;
        }
        return s;
      });
      this.elements.push(element);
    },
    loadElements() {
      $.get(this.urls.elements_url, (result) => {
        this.elements = result.data;
        this.$emit('result:elements:loaded');
      });
    },
    loadAttachments() {
      this.attachmentsReady = false;

      $.get(this.urls.attachments_url, (result) => {
        this.attachments = result.data;
        this.$emit('result:attachments:loaded');
        if (this.attachments.findIndex((e) => e.attributes.attached === false) >= 0) {
          setTimeout(() => {
            this.loadAttachments();
          }, 10000);
        } else {
          this.attachmentsReady = true;
        }
      });
      this.showFileModal = false;
    },
    attachmentDeleted(id) {
      this.attachments = this.attachments.filter((a) => a.id !== id);
      this.$emit('resultUpdated');
    },
    updateAttachment(attachment) {
      const index = this.attachments.findIndex((a) => a.id === attachment.id);
      if (index !== -1) {
        this.attachments[index] = attachment;
      }
    },
    createElement(elementType, tableDimensions = null, name = '') {
      let plateTemplate = tableDimensions != null;
      tableDimensions ||= [5, 5];

      $.post(this.urls[`create_${elementType}_url`], { tableDimensions, plateTemplate, name }, (result) => {
        result.data.isNew = true;
        this.elements.push(result.data);

        if (this.isCollapsed) {
          this.$refs.toggleElement.click();
        }
        this.$emit('resultUpdated');
      }).fail(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      }).done(() => {
        this.$parent.$nextTick(() => {
          const children = this.$refs.resultContainer.querySelectorAll('.result-element');
          const lastChild = children[children.length - 1];

          lastChild.scrollIntoView(false);
          window.scrollBy({
            top: 200,
            behavior: 'smooth'
          });
        });
      });
    },
    openCustomWellPlateModal() {
      this.customWellPlate = true;
    },
    closeCustomWellPlateModal() {
      this.customWellPlate = false;
    },
    archiveResult() {
      axios.post(this.urls.archive_url).then((response) => {
        this.$emit('result:archived', this.result.id);
      });
    },
    restoreResult() {
      axios.post(this.urls.restore_url).then((response) => {
        this.$emit('result:restored', this.result.id);
      });
    },
    showDeleteModal() {
      this.confirmingDelete = true;
    },
    closeDeleteModal() {
      this.confirmingDelete = false;
    },
    deleteResult() {
      axios.delete(this.urls.delete_url).then((response) => {
        this.$emit('result:deleted', this.result.id);
      });
    },
    duplicateResult() {
      axios.post(this.urls.duplicate_url).then((_) => {
        this.$emit('result:duplicated');
      });
    },
    moveElement(position, target_id) {
      this.elements.splice(position, 1);
      this.elements.map((e) => {
        if (e.attributes.position >= position) {
          e.attributes.position -= 1;
        }
        return e;
      });
      this.$emit('resultUpdated');
      this.$emit('result:move_element', target_id);
    },
    moveAttachment(id, target_id) {
      this.attachments = this.attachments.filter((a) => a.id !== id);
      this.$emit('resultUpdated');
      this.$emit('result:move_attachment', target_id);
    },
    updateName(name) {
      axios.patch(this.urls.update_url, { result: { name } }).then((_) => {
        this.$emit('updated');
      });
    },
    updateLinkedSteps(steps) {
      window.destroyTooltip(this.$refs.linkButton);

      this.$emit('result:update', this.result.id,{
        steps: steps
      });

      this.$nextTick(() => window.initTooltip(this.$refs.linkButton));
    },
    protocolUrl(step_id) {
      return protocols_my_module_path({ id: this.result.attributes.my_module_id }, { step_id: step_id })
    },
  }
};
</script>
