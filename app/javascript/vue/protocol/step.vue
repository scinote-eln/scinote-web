<template>
  <div ref="stepContainer" class="step-container pr-8"
       :id="`stepContainer${step.id}`"
       @drop.prevent="dropFile"
       @dragenter.prevent="dragEnter($event)"
       @dragover.prevent
       :data-id="step.id"
       :class="{ 'draging-file': dragingFile, 'editing-name': editingName, 'locked': !urls.update_url }"
  >
    <div class="drop-message" @dragleave.prevent="!showFileModal ? dragingFile = false : null">
      {{ i18n.t('protocols.steps.drop_message', { position: step.attributes.position + 1 }) }}
      <StorageUsage v-if="showStorageUsage()" :parent="step"/>
    </div>
    <div class="step-header">
      <div class="step-element-header" :class="{ 'no-hover': !urls.update_url }">
        <div class="flex items-center gap-4 py-0.5 border-0 border-y border-transparent border-solid">
          <a class="step-collapse-link hover:no-underline focus:no-underline"
            :href="'#stepBody' + step.id"
            data-toggle="collapse"
            data-remote="true"
            @click="toggleCollapsed">
              <span class="sn-icon sn-icon-right "></span>
          </a>
          <div v-if="!inRepository" class="step-complete-container" :class="{ 'step-element--locked': !urls.state_url }">
            <div :class="`step-state ${step.attributes.completed ? 'completed' : ''}`"
                 @click="changeState"
                 @keyup.enter="changeState"
                 tabindex="0"
                 :title="step.attributes.completed ? i18n.t('protocols.steps.status.uncomplete') : i18n.t('protocols.steps.status.complete')"
            ></div>
          </div>
          <div class="step-position  leading-5">
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
          :data-object-id="step.id"
          ref="marvinJsButton"
          :data-marvin-url="step.attributes.marvinjs_context?.marvin_js_asset_url"
          :data-object-type="step.attributes.type"
          tabindex="0"
        ></span> <!-- Hidden element to support legacy code -->

        <a href="#"
           v-if="!inRepository"
           ref="comments"
           class="open-comments-sidebar btn icon-btn btn-light"
           data-turbolinks="false"
           data-object-type="Step"
           @click="openCommentsSidebar"
           :data-object-id="step.id">
          <i class="sn-icon sn-icon-comments"></i>
          <span class="comments-counter" v-show="step.attributes.comments_count"
                :id="`comment-count-${step.id}`"
                :class="{'unseen': step.attributes.unseen_comments}"
          >
            {{ step.attributes.comments_count }}
          </span>
        </a>
        <MenuDropdown
          :listItems="this.actionsMenu"
          :btnClasses="'btn btn-light icon-btn'"
          :position="'right'"
          :btnIcon="'sn-icon sn-icon-more-hori'"
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
                    @attachments:openFileModal="showFileModal = true"
                    @attachment:deleted="attachmentDeleted"
                    @attachment:uploaded="loadAttachments"
                    @attachment:changed="reloadAttachment"
                    @attachments:order="changeAttachmentsOrder"
                    @attachment:moved="moveAttachment"
                    @attachments:viewMode="changeAttachmentsViewMode"
                    @attachment:viewMode="updateAttachmentViewMode"/>
      </div>
    </div>
    <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
    <ReorderableItemsModal v-if="reordering"
      :title="i18n.t('protocols.steps.modals.reorder_elements.title', { step_position: step.attributes.position + 1 })"
      :items="reorderableElements"
      @reorder="updateElementOrder"
      @close="closeReorderModal"
    />
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
  import deleteStepModal from './modals/delete_step.vue'
  import Attachments from '../shared/content/attachments.vue'
  import ReorderableItemsModal from '../shared/reorderable_items_modal.vue'
  import MenuDropdown from '../shared/menu_dropdown.vue'

  import UtilsMixin from '../mixins/utils.js'
  import AttachmentsMixin from '../shared/content/mixins/attachments.js'
  import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js'
  import OveMixin from '../shared/content/attachments/mixins/ove.js'
  import StorageUsage from '../shared/content/attachments/storage_usage.vue'
  import axios from '../../packs/custom_axios';

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
        showFileModal: false,
        showCommentsSidebar: false,
        dragingFile: false,
        reordering: false,
        isCollapsed: false,
        editingName: false,
        inlineEditError: null,
        wellPlateOptions: [
          { text: I18n.t('protocols.steps.insert.well_plate_options.32_x_48'), emit: 'create:table', params: [32, 48] },
          { text: I18n.t('protocols.steps.insert.well_plate_options.16_x_24'), emit: 'create:table', params: [16, 24] },
          { text: I18n.t('protocols.steps.insert.well_plate_options.8_x_12'), emit: 'create:table', params: [8, 12] },
          { text: I18n.t('protocols.steps.insert.well_plate_options.6_x_8'), emit: 'create:table', params: [6, 8] },
          { text: I18n.t('protocols.steps.insert.well_plate_options.4_x_6'), emit: 'create:table', params: [4, 6] },
          { text: I18n.t('protocols.steps.insert.well_plate_options.3_x_4'), emit: 'create:table', params: [3, 4]},
          { text: I18n.t('protocols.steps.insert.well_plate_options.2_x_3'), emit: 'create:table', params: [2, 3] }
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
      MenuDropdown
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
      }
    },
    mounted() {
      $(this.$refs.comments).data('closeCallback', this.closeCommentsSidebar);
      $(this.$refs.comments).data('openCallback', this.closeCommentsSidebar);
      $(this.$refs.actionsDropdownButton).on('shown.bs.dropdown hidden.bs.dropdown', () => {
        this.handleDropdownPosition(this.$refs.actionsDropdownButton, this.$refs.actionsDropdown)
      });
      $(this.$refs.elementsDropdownButton).on('shown.bs.dropdown hidden.bs.dropdown', () => {
        this.handleDropdownPosition(this.$refs.elementsDropdownButton, this.$refs.elementsDropdown)
      });
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
            emit: 'create:file'
          }]);
        }
        if (this.step.attributes.wopi_enabled) {
          menu = menu.concat([{
            text: this.i18n.t('assets.create_wopi_file.button_text'),
            emit: 'create:wopi_file'
          }]);
        }
        if (this.step.attributes.open_vector_editor_context.new_sequence_asset_url) {
          menu = menu.concat([{
            text: this.i18n.t('open_vector_editor.new_sequence_file'),
            emit: 'create:ove_file'
          }]);
        }
        if (this.step.attributes.marvinjs_enabled) {
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
                    text: this.i18n.t('protocols.steps.insert.text'),
                    emit: 'create:text'
                  },{
                    text: this.i18n.t('protocols.steps.insert.attachment'),
                    submenu: this.filesMenu,
                    position: 'left'
                  },{
                    text: this.i18n.t('protocols.steps.insert.table'),
                    emit: 'create:table'
                  },{
                    text: this.i18n.t('protocols.steps.insert.well_plate'),
                    submenu: this.wellPlateOptions,
                    position: 'left'
                  },{
                    text: this.i18n.t('protocols.steps.insert.checklist'),
                    emit: 'create:checklist'
                  }]);
        }

        return menu;
      },
      actionsMenu() {
        let menu = [];
        if (this.urls.reorder_elements_url) {
          menu = menu.concat([{
            text: this.i18n.t('protocols.steps.options_dropdown.rearrange'),
            emit: 'reorder'
          }]);
        }
        if (this.urls.duplicate_step_url) {
          menu = menu.concat([{
            text: this.i18n.t('protocols.steps.options_dropdown.duplicate'),
            emit: 'duplicate'
          }]);
        }
        if (this.urls.delete_url) {
          menu = menu.concat([{
            text: this.i18n.t('protocols.steps.options_dropdown.delete'),
            emit: 'delete'
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

        if (skipRequest) {
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
      createElement(elementType, tableDimensions = null) {
        let plateTemplate = tableDimensions != null;
        tableDimensions ||= [5, 5];
        $.post(this.urls[`create_${elementType}_url`], { tableDimensions: tableDimensions, plateTemplate: plateTemplate }, (result) => {
          result.data.isNew = true;
          this.elements.push(result.data)
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
      openCommentsSidebar() {
        $('.comments-sidebar .close-btn').click();
        this.showCommentsSidebar = true
      },
      attachmentDeleted(id) {
        this.attachments = this.attachments.filter((a) => a.id !== id );
        this.$emit('stepUpdated');
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
      }
    }
  }
</script>
