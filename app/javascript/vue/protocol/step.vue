<template>
  <div class="step-container"
       :id="`stepContainer${step.id}`"
       :class="{'showing-comments': showCommentsSidebar}"
  >
    <div class="step-header">
      <a class="step-collapse-link"
           :href="'#stepBody' + step.id"
           data-toggle="collapse"
           data-remote="true">
          <span class="fas fa-caret-right"></span>
      </a>
      <div class="step-complete-container">
        <div :class="`step-state ${step.attributes.completed ? 'completed' : ''}`" @click="changeState"></div>
      </div>
      <div class="step-position">
        {{ step.attributes.position + 1 }}.
      </div>
      <div class="step-name-container">
        <InlineEdit
          :value="step.attributes.name"
          :characterLimit="255"
          :allowBlank="false"
          :attributeName="`${i18n.t('Step')} ${i18n.t('name')}`"
          @update="updateName"
        />
      </div>
      <div class="step-actions-container">
        <div class="dropdown">
          <button class="btn btn-light dropdown-toggle insert-button" type="button" :id="'stepInserMenu_' + step.id" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            {{ i18n.t('protocols.steps.insert.button') }}
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu insert-element-dropdown" :aria-labelledby="'stepInserMenu_' + step.id">
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
           ref="comments"
           class="open-comments-sidebar btn icon-btn btn-light"
           data-turbolinks="false"
           data-object-type="Step"
           @click="showCommentsSidebar = true"
           :data-object-id="step.id">
          <i class="fas fa-comment"></i>
          <span class="comments-counter"
                :id="`comment-count-${step.id}`"
                :class="{'unseen': step.attributes.unseen_comments}"
          >
            {{ step.attributes.comments_count }}
          </span>
        </a>
        <button class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div class="collapse in" :id="'stepBody' + step.id">
      <template v-for="(element, index) in elements">
        <component
          :is="elements[index].attributes.orderable_type"
          :key="index"
          :element.sync="elements[index]"
          @component:delete="deleteComponent"
          @update="updateComponent" />
      </template>
      <Attachments :step="step"
                   :attachments="attachments"
                   @attachments:order="changeAttachmentsOrder"
                   @attachments:viewMode="changeAttachmentsViewMode"
                   @attachment:viewMode="updateAttachmentViewMode"/>
    </div>
    <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
    <fileModal v-if="showFileModal"
               :step="step"
               @cancel="showFileModal = false"
               @files="uploadFiles"
               @attachmentUploaded="addAttachment"
               @attachmentsChanged="loadAttachments"
    />
  </div>
</template>

 <script>
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import StepTable from 'vue/protocol/step_components/table.vue'
  import StepText from 'vue/protocol/step_components/text.vue'
  import Checklist from 'vue/protocol/step_components/checklist.vue'
  import deleteStepModal from 'vue/protocol/modals/delete_step.vue'
  import Attachments from 'vue/protocol/attachments.vue'
  import fileModal from 'vue/protocol/step_attachments/file_modal.vue'
  import AttachmentsMixin from 'vue/protocol/mixins/attachments.js'

  export default {
    name: 'StepContainer',
    props: {
      step: {
        type: Object,
        required: true
      }
    },
    data() {
      return {
        elements: [],
        attachments: [],
        confirmingDelete: false,
        showFileModal: false,
        showCommentsSidebar: false
      }
    },
    mixins: [AttachmentsMixin],
    components: {
      InlineEdit,
      StepTable,
      StepText,
      Checklist,
      deleteStepModal,
      fileModal,
      Attachments
    },
    created() {
      this.loadAttachments();
      this.loadElements();
    },
    mounted() {
      $(this.$refs.comments).data('closeCallback', this.closeCommentsSidebar)
    },
    methods: {
      loadAttachments() {
        $.get(this.step.attributes.urls.attachments_url, (result) => {
          this.attachments = result.data
        });
      },
      loadElements() {
        $.get(this.step.attributes.urls.elements_url, (result) => {
          this.elements = result.data
        });
      },
      showDeleteModal() {
        this.confirmingDelete = true;
      },
      closeDeleteModal() {
        this.confirmingDelete = false;
      },
      deleteStep() {
        $.ajax({
          url: this.step.attributes.urls.delete_url,
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
        this.step.attributes.completed = !this.step.attributes.completed;
        this.$emit('step:update', this.step.attributes)
        $.post(this.step.attributes.urls.state_url, {completed: this.step.attributes.completed}).error(() => {
          this.step.attributes.completed = !this.step.attributes.completed;
          this.$emit('step:update', this.step.attributes)
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        })
      },
      deleteComponent(position) {
        this.elements.splice(position, 1)
        let unordered_elements = this.elements.map( e => {
          if (e.attributes.position >= position) {
            e.attributes.position -= 1;
          }
          return e;
        })
        this.reorderComponents(unordered_elements)

      },
      updateComponent(element, skipRequest=false) {
        let index = this.elements.findIndex((e) => e.id === element.id);

        if (skipRequest) {
          this.elements[index].orderable = element;
        } else {
          $.ajax({
            url: element.attributes.orderable.urls.update_url,
            method: 'PUT',
            data: element.attributes.orderable,
            success: (result) => {
              this.elements[index].orderable = result;
            }
          }).error(() => {
            HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
          })
        }
      },
      reorderComponents(elements) {
        this.elements = elements.sort((a, b) => a.attributes.position - b.attributes.position);
      },
      updateName(newName) {
        $.ajax({
          url: this.step.attributes.urls.update_url,
          type: 'PATCH',
          data: {step: {name: newName}},
          success: (result) => {
            this.$emit('step:update', result.data.attributes)
          }
        });
      },
      createElement(elementType) {
        $.post(this.step.attributes.urls[`create_${elementType}_url`], (result) => {
          this.elements.push(result.data)
        }).error(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        })
      },
      addAttachment(attachment) {
        this.attachments.push(attachment);
      },
      closeCommentsSidebar() {
        this.showCommentsSidebar = false
      }
    }
  }
</script>
