<template>
  <div ref="stepContainer" class="step-container"
       :id="`stepContainer${step.id}`"
       @drop.prevent="dropFile"
       @dragenter.prevent="dragEnter($event)"
       @dragover.prevent
       :class="{ 'draging-file': dragingFile, 'showing-comments': showCommentsSidebar, 'editing-name': editingName }"
  >
    <div class="drop-message" @dragleave.prevent="!showFileModal ? dragingFile = false : null">
      {{ i18n.t('protocols.steps.drop_message', { position: step.attributes.position + 1 }) }}
      <StorageUsage v-if="showStorageUsage()" :parent="step"/>
    </div>
    <div class="step-header">
      <div class="step-element-header" :class="{ 'no-hover': !urls.update_url }">
        <div class="step-controls">
          <div v-if="reorderStepUrl" class="step-element-grip" @click="$emit('reorder')" :class="{ 'step-element--locked': !urls.update_url }">
            <i class="sn-icon sn-icon-sort"></i>
          </div>
          <div v-else class="step-element-grip-placeholder"></div>
          <a class="step-collapse-link hover:no-underline focus:no-underline"
            :href="'#stepBody' + step.id"
            data-toggle="collapse"
            data-remote="true"
            @click="toggleCollapsed">
              <span class="sn-icon sn-icon-right "></span>
          </a>
          <div v-if="!inRepository" class="step-complete-container mx-1.5" :class="{ 'step-element--locked': !urls.state_url }">
            <div :class="`step-state ${step.attributes.completed ? 'completed' : ''}`"
                 @click="changeState"
                 @keyup.enter="changeState"
                 tabindex="0"
                 :title="step.attributes.completed ? i18n.t('protocols.steps.status.uncomplete') : i18n.t('protocols.steps.status.complete')"
            ></div>
          </div>
          <div class="step-position">
            {{ step.attributes.position + 1 }}.
          </div>
        </div>
        <div class="step-name-container" :class="{'step-element--locked': !urls.update_url}">
          <InlineEdit
            :value="step.attributes.name"
            :class="{ 'step-element--locked': !urls.update_url }"
            :characterLimit="255"
            :allowBlank="false"
            :attributeName="`${i18n.t('Step')} ${i18n.t('name')}`"
            :autofocus="editingName"
            :placeholder="i18n.t('protocols.steps.placeholder')"
            :defaultValue="i18n.t('protocols.steps.default_name')"
            @editingEnabled="editingName = true"
            @editingDisabled="editingName = false"
            :editOnload="step.newStep == true"
            @update="updateName"
          />
        </div>
        <button v-if="urls.update_url && !editingName" class="step-name-edit-icon btn btn-xs icon-btn btn-light my-1.5" @click="editingName = true">
          <i class="sn-icon sn-icon-edit"></i>
        </button>
      </div>
      <div class="step-actions-container">
        <input type="file" class="hidden" ref="fileSelector" @change="loadFromComputer" multiple />
        <div ref="elementsDropdownButton" v-if="urls.update_url"  class="dropdown">
          <button class="btn btn-light dropdown-toggle insert-button" type="button" :id="'stepInserMenu_' + step.id" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            {{ i18n.t('protocols.steps.insert.button') }}
            <span class="sn-icon sn-icon-down"></span>
          </button>
          <ul ref="elementsDropdown" class="dropdown-menu insert-element-dropdown dropdown-menu-right" :aria-labelledby="'stepInserMenu_' + step.id">
            <li class="title">
              {{ i18n.t('protocols.steps.insert.title') }}
            </li>
            <li class="action" @click="createElement('table')">
              <i class="sn-icon sn-icon-tables"></i>
              {{ i18n.t('protocols.steps.insert.table') }}
            </li>
            <li class="action dropdown-submenu-item">
              <i class="sn-icon sn-icon-tables"></i>
              {{ i18n.t('protocols.steps.insert.well_plate') }}
              <span class="caret"></span>

              <ul class="dropdown-submenu">
                <li v-for="option in wellPlateOptions" :key="option.dimensions.toString()" class="action" @click="createElement('table', option.dimensions, true)">
                  {{ i18n.t(option.label) }}
                </li>
              </ul>
            </li>
            <li class="action"  @click="createElement('checklist')">
              <i class="sn-icon sn-icon-activities"></i>
              {{ i18n.t('protocols.steps.insert.checklist') }}
            </li>
            <li class="action"  @click="createElement('text')">
              <i class="sn-icon sn-icon-result-text"></i>
              {{ i18n.t('protocols.steps.insert.text') }}
            </li>
            <li class="action dropdown-submenu-item">
              <i class="sn-icon sn-icon-files"></i>
              {{ i18n.t('protocols.steps.insert.attachment') }}
              <span class="caret"></span>
              <ul class="dropdown-submenu">
                <li class="action" @click="openLoadFromComputer">
                  {{ i18n.t('protocols.steps.insert.add_file') }}
                </li>
                <li class="action" v-if="step.attributes.wopi_enabled" @click="openWopiFileModal">
                  {{ i18n.t('assets.create_wopi_file.button_text') }}
                </li>
                <li class="action" v-if="step.attributes.marvinjs_enabled" @click="openMarvinJsModal($refs.marvinJsButton)">
                  <span
                    class="new-marvinjs-upload-button text-sn-black text-decoration-none"
                    :data-object-id="step.id"
                    ref="marvinJsButton"
                    :data-marvin-url="step.attributes.marvinjs_context.marvin_js_asset_url"
                    :data-object-type="step.attributes.type"
                    tabindex="0"
                  >
                    {{ i18n.t('marvinjs.new_button') }}
                  </span>
                </li>
              </ul>
            </li>
          </ul>
        </div>
        <a href="#"
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
                :class="{'unseen': step.attributes.unseen_comments}"
          >
            {{ step.attributes.comments_count }}
          </span>
        </a>
        <div v-if="urls.update_url" class="step-actions-container">
          <div ref="actionsDropdownButton" class="dropdown">
            <button class="btn btn-light icon-btn dropdown-toggle insert-button" type="button" :id="'stepOptionsMenu_' + step.id" data-toggle="dropdown" data-display="static" aria-haspopup="true" aria-expanded="true">
              <i class="sn-icon sn-icon-more-hori"></i>
            </button>
            <ul ref="actionsDropdown" class="dropdown-menu dropdown-menu-right insert-element-dropdown" :aria-labelledby="'stepOptionsMenu_' + step.id">
              <li class="title">
                {{ i18n.t('protocols.steps.options_dropdown.title') }}
              </li>
              <li v-if="urls.reorder_elements_url" class="action"  @click="openReorderModal" :class="{ 'disabled': elements.length < 2 }">
                <i class="sn-icon sn-icon-sort"></i>
                {{ i18n.t('protocols.steps.options_dropdown.rearrange') }}
              </li>
              <li v-if="urls.duplicate_step_url" class="action" @click="duplicateStep">
                <i class="sn-icon sn-icon-duplicate"></i>
                {{ i18n.t('protocols.steps.options_dropdown.duplicate') }}
              </li>
              <li v-if="urls.delete_url" class="action" @click="showDeleteModal">
                <i class="sn-icon sn-icon-delete"></i>
                {{ i18n.t('protocols.steps.options_dropdown.delete') }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    <div class="collapse in" :id="'stepBody' + step.id">
      <div class="step-elements">
        <div class="step-timestamp">{{ i18n.t('protocols.steps.timestamp', {date: step.attributes.created_at, user: step.attributes.created_by}) }}</div>
        <template v-for="(element, index) in orderedElements">
          <component
            :is="elements[index].attributes.orderable_type"
            :key="index"
            :element.sync="elements[index]"
            :inRepository="inRepository"
            :reorderElementUrl="elements.length > 1 ? urls.reorder_elements_url : ''"
            :assignableMyModuleId="assignableMyModuleId"
            :isNew="element.isNew"
            @component:delete="deleteElement"
            @update="updateElement"
            @reorder="openReorderModal"
            @component:insert="insertElement"
          />
        </template>
        <Attachments v-if="attachments.length"
                    :parent="step"
                    :attachments="attachments"
                    :attachmentsReady="attachmentsReady"
                    @attachments:openFileModal="showFileModal = true"
                    @attachment:deleted="attachmentDeleted"
                    @attachment:uploaded="loadAttachments"
                    @attachments:order="changeAttachmentsOrder"
                    @attachments:viewMode="changeAttachmentsViewMode"
                    @attachment:viewMode="updateAttachmentViewMode"/>
      </div>
    </div>
    <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
    <clipboardPasteModal v-if="showClipboardPasteModal"
                         :parent="step"
                         :image="pasteImages"
                         @files="uploadFiles"
                         @cancel="showClipboardPasteModal = false"
    />
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
  import clipboardPasteModal from '../shared/content/attachments/clipboard_paste_modal.vue'
  import ReorderableItemsModal from '../shared/reorderable_items_modal.vue'

  import UtilsMixin from '../mixins/utils.js'
  import AttachmentsMixin from '../shared/content/mixins/attachments.js'
  import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js'
  import StorageUsage from '../shared/content/attachments/storage_usage.vue'

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
      }
    },
    data() {
      return {
        elements: [],
        attachments: [],
        attachmentsReady: false,
        confirmingDelete: false,
        showFileModal: false,
        showClipboardPasteModal: false,
        showCommentsSidebar: false,
        dragingFile: false,
        reordering: false,
        isCollapsed: false,
        editingName: false,
        wellPlateOptions: [
          { label: 'protocols.steps.insert.well_plate_options.32_x_48', dimensions: [32, 48] },
          { label: 'protocols.steps.insert.well_plate_options.16_x_24', dimensions: [16, 24] },
          { label: 'protocols.steps.insert.well_plate_options.8_x_12', dimensions: [8, 12] },
          { label: 'protocols.steps.insert.well_plate_options.6_x_8', dimensions: [6, 8] },
          { label: 'protocols.steps.insert.well_plate_options.6_x_4', dimensions: [6, 4] },
          { label: 'protocols.steps.insert.well_plate_options.2_x_3', dimensions: [2, 3] }
        ]
      }
    },
    mixins: [UtilsMixin, AttachmentsMixin, WopiFileModal],
    components: {
      InlineEdit,
      StepTable,
      StepText,
      Checklist,
      deleteStepModal,
      clipboardPasteModal,
      Attachments,
      StorageUsage,
      ReorderableItemsModal
    },
    created() {
      this.loadAttachments();
      this.loadElements();
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
        }
      },
      loadAttachments() {
        this.attachmentsReady = false

        $.get(this.urls.attachments_url, (result) => {
          this.attachments = result.data

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
      loadElements() {
        $.get(this.urls.elements_url, (result) => {
          this.elements = result.data
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
      createElement(elementType, tableDimensions = [5,5], plateTemplate = false) {
        $.post(this.urls[`create_${elementType}_url`], { tableDimensions: tableDimensions, plateTemplate: plateTemplate }, (result) => {
          result.data.isNew = true;
          this.elements.push(result.data)
          this.$emit('stepUpdated')
        }).fail(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        }).done(() => {
          this.$parent.$nextTick(() => {
            const children = this.$children
            const lastChild = children[children.length - 1]
            lastChild.$el.scrollIntoView(false)
            window.scrollBy({
              top: 200,
              behavior: 'smooth'
            });
          })
        });
      },
      addAttachment(attachment) {
        this.attachments.push(attachment);
        this.showFileModal = false;
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
      copyPasteImageModal(pasteImages) {
        this.pasteImages = pasteImages;
        this.showClipboardPasteModal = true;
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
