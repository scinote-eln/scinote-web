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
      <StorageUsage v-if="showStorageUsage()" :step="step"/>
    </div>
    <div class="step-header">
      <div class="step-element-header">
        <div class="step-controls">
          <div v-if="reorderStepUrl" class="step-element-grip" @click="$emit('reorder')">
            <i class="fas fas-rotated-90 fa-exchange-alt"></i>
          </div>
          <div v-else class="step-element-grip-placeholder"></div>
          <a class="step-collapse-link"
            :href="'#stepBody' + step.id"
            data-toggle="collapse"
            data-remote="true"
            @click="toggleCollapsed">
              <span class="fas fa-caret-right"></span>
          </a>
          <div v-if="!inRepository" class="step-complete-container">
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
        <div class="step-name-container" :class="{'strikethrough': step.attributes.completed}">
          <InlineEdit
            v-if="urls.update_url"
            :value="step.attributes.name"
            :characterLimit="255"
            :allowBlank="false"
            :attributeName="`${i18n.t('Step')} ${i18n.t('name')}`"
            :autofocus="editingName"
            @editingEnabled="editingName = true"
            @editingDisabled="editingName = false"
            :editOnload="step.newStep == true"
            @update="updateName"
          />
          <span v-else>
            {{ step.attributes.name }}
          </span>
        </div>
        <i v-if="urls.update_url && !editingName" class="step-name-edit-icon fas fa-pen" @click="editingName = true"></i>
      </div>
      <div class="step-actions-container">
        <div ref="actionsDropdownButton" v-if="urls.update_url"  class="dropdown">
          <button class="btn btn-light dropdown-toggle insert-button" type="button" :id="'stepInserMenu_' + step.id" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            {{ i18n.t('protocols.steps.insert.button') }}
            <span class="caret"></span>
          </button>
          <ul ref="actionsDropdown" class="dropdown-menu insert-element-dropdown" :aria-labelledby="'stepInserMenu_' + step.id">
            <li class="title">
              {{ i18n.t('protocols.steps.insert.title') }}
            </li>
            <li class="action" @click="createElement('table')">
              <i class="fas fa-table"></i>
              {{ i18n.t('protocols.steps.insert.table') }}
            </li>
            <li class="action" @click="createElement('checklist')">
              <i class="fas fa-list"></i>
              {{ i18n.t('protocols.steps.insert.checklist') }}
            </li>
            <li class="action"  @click="createElement('text')">
              <i class="fas fa-font"></i>
              {{ i18n.t('protocols.steps.insert.text') }}
            </li>
            <li class="action"  @click="showFileModal = true">
              <i class="fas fa-paperclip"></i>
              {{ i18n.t('protocols.steps.insert.attachment') }}
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
          <i class="fas fa-comment"></i>
          <span class="comments-counter"
                :id="`comment-count-${step.id}`"
                :class="{'unseen': step.attributes.unseen_comments}"
          >
            {{ step.attributes.comments_count }}
          </span>
        </a>
        <div v-if="urls.update_url" class="step-actions-container">
          <div class="dropdown">
            <button class="btn btn-light dropdown-toggle insert-button" type="button" :id="'stepInserMenu_' + step.id" data-toggle="dropdown" data-display="static" aria-haspopup="true" aria-expanded="true">
              <i class="fas fa-ellipsis-h"></i>
            </button>
            <ul class="dropdown-menu dropdown-menu-right insert-element-dropdown" :aria-labelledby="'stepInserMenu_' + step.id">
              <li class="title">
                {{ i18n.t('protocols.steps.options_dropdown.title') }}
              </li>
              <li v-if="urls.reorder_elements_url" class="action"  @click="openReorderModal" :class="{ 'disabled': elements.length < 2 }">
                <i class="fas fas-rotated-90 fa-exchange-alt"></i>
                {{ i18n.t('protocols.steps.options_dropdown.rearrange') }}
              </li>
              <li v-if="urls.delete_url" class="action" @click="showDeleteModal">
                <i class="fas fa-trash"></i>
                {{ i18n.t('protocols.steps.options_dropdown.delete') }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    <div class="collapse in" :id="'stepBody' + step.id">
      <div class="step-elements">
        <template v-for="(element, index) in elements">
          <component
            :is="elements[index].attributes.orderable_type"
            :key="index"
            :element.sync="elements[index]"
            :inRepository="inRepository"
            :reorderElementUrl="elements.length > 1 ? urls.reorder_elements_url : ''"
            :isNew="element.isNew"
            @component:delete="deleteElement"
            @update="updateElement"
            @reorder="openReorderModal"
          />
        </template>
        <Attachments v-if="attachments.length"
                    :step="step"
                    :attachments="attachments"
                    @attachments:openFileModal="showFileModal = true"
                    @attachment:deleted="attachmentDeleted"
                    @attachment:uploaded="loadAttachments"
                    @attachments:order="changeAttachmentsOrder"
                    @attachments:viewMode="changeAttachmentsViewMode"
                    @attachment:viewMode="updateAttachmentViewMode"/>
      </div>
    </div>
    <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
    <fileModal v-if="showFileModal"
               :step="step"
               @cancel="showFileModal = false"
               @files="uploadFiles"
               @attachmentUploaded="addAttachment"
               @attachmentsChanged="loadAttachments"
               @copyPasteImageModal="copyPasteImageModal"
    />
    <clipboardPasteModal v-if="showClipboardPasteModal"
                         :step="step"
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

  import InlineEdit from 'vue/shared/inline_edit.vue'
  import StepTable from 'vue/protocol/step_elements/table.vue'
  import StepText from 'vue/protocol/step_elements/text.vue'
  import Checklist from 'vue/protocol/step_elements/checklist.vue'
  import deleteStepModal from 'vue/protocol/modals/delete_step.vue'
  import Attachments from 'vue/protocol/attachments.vue'
  import fileModal from 'vue/protocol/step_attachments/file_modal.vue'
  import clipboardPasteModal from 'vue/protocol/step_attachments/clipboard_paste_modal.vue'
  import ReorderableItemsModal from 'vue/protocol/modals/reorderable_items_modal.vue'

  import UtilsMixin from 'vue/protocol/mixins/utils.js'
  import AttachmentsMixin from 'vue/protocol/mixins/attachments.js'
  import StorageUsage from 'vue/protocol/storage_usage.vue'

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
      }
    },
    data() {
      return {
        elements: [],
        attachments: [],
        confirmingDelete: false,
        showFileModal: false,
        showClipboardPasteModal: false,
        showCommentsSidebar: false,
        dragingFile: false,
        reordering: false,
        isCollapsed: false,
        editingName: false
      }
    },
    mixins: [UtilsMixin, AttachmentsMixin],
    components: {
      InlineEdit,
      StepTable,
      StepText,
      Checklist,
      deleteStepModal,
      fileModal,
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
      $(this.$refs.actionsDropdownButton).on('shown.bs.dropdown hidden.bs.dropdown', this.handleDropdownPosition);
    },
    computed: {
      reorderableElements() {
        return this.elements.map((e) => { return { id: e.id, attributes: e.attributes.orderable } })
      },
      urls() {
        return this.step.attributes.urls || {}
      }
    },
    methods: {
      dragEnter(e) {
        if (this.showFileModal) return;

        // Detect if dragged element is a file
        // https://stackoverflow.com/a/8494918
        let dt = e.dataTransfer;
        if (dt.types && (dt.types.indexOf ? dt.types.indexOf('Files') != -1 : dt.types.contains('Files'))) {
          this.dragingFile = true;
        }
      },
      loadAttachments() {
        $.get(this.urls.attachments_url, (result) => {
          this.attachments = result.data
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
        $.post(this.urls.state_url, {completed: this.step.attributes.completed}).error(() => {
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
        this.reorderElements(unorderedElements)
        this.$emit('stepUpdated')
      },
      updateElement(element, skipRequest=false) {
        let index = this.elements.findIndex((e) => e.id === element.id);

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
            }
          }).error(() => {
            HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
          })
        }
      },
      reorderElements(elements) {
        this.elements = elements.sort((a, b) => a.attributes.position - b.attributes.position);
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
          error: (() => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger'))
        });

        this.reorderElements(this.elements);
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
          }
        });
      },
      createElement(elementType) {
        $.post(this.urls[`create_${elementType}_url`], (result) => {
          result.data.isNew = true;
          this.elements.push(result.data)
        }).error(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        })
      },
      addAttachment(attachment) {
        this.attachments.push(attachment);
        this.showFileModal = false;
      },
      openCommentsSidebar() {
        $('.comments-sidebar .close-btn').click();
        this.showCommentsSidebar = true
      },
      attachmentDeleted() {
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
      handleDropdownPosition() {
        this.$refs.actionsDropdownButton.classList.toggle("dropup", !this.isInViewport(this.$refs.actionsDropdown));
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
      }
    }
  }
</script>
