<template>
  <div v-if="protocol.id" class="task-protocol">
    <div ref="header" class="task-section-header ml-[-1rem] w-[calc(100%_+_2rem)] px-4 bg-sn-white sticky top-0 transition" v-if="!inRepository">
      <div class="flex items-center grow">
        <div class="portocol-header-left-part grow">
          <template v-if="headerSticked && moduleName">
            <i class="sn-icon sn-icon-navigator sci--layout--navigator-open cursor-pointer p-1.5 border rounded border-sn-light-grey mr-4"></i>
            <div @click="scrollTop" class="task-section-title w-[calc(100%_-_35rem)] min-w-[5rem] cursor-pointer">
              <h2 class="truncate leading-6">{{ moduleName }}</h2>
            </div>
          </template>
          <template v-else>
            <a class="task-section-caret" tabindex="0" role="button" data-toggle="collapse" href="#protocol-content" aria-expanded="true" aria-controls="protocol-content">
              <i class="sn-icon sn-icon-right"></i>
              <div class="task-section-title truncate">
                <h2>{{ i18n.t('Protocol') }}</h2>
              </div>
            </a>
          </template>
          <div :class="{'hidden': headerSticked}">
            <div class="my-module-protocol-status">
              <!-- protocol status dropdown gets mounted here -->
            </div>
          </div>
        </div>
      </div>
      <div class="actions-block">
        <div class="protocol-buttons-group shrink-0">
          <a v-if="urls.add_step_url"
             class="btn btn-secondary"
             :title="i18n.t('protocols.steps.new_step_title')"
             @keyup.enter="addStep(steps.length)"
             @click="addStep(steps.length)"
             tabindex="0">
              <span class="sn-icon sn-icon-new-task" aria-hidden="true"></span>
              <span>{{ i18n.t("protocols.steps.new_step") }}</span>
          </a>
          <template v-if="steps.length > 0">
            <button class="btn btn-secondary" @click="collapseSteps" tabindex="0">
              {{ i18n.t("protocols.steps.collapse_label") }}
            </button>
            <button class="btn btn-secondary" @click="expandSteps" tabindex="0">
              {{ i18n.t("protocols.steps.expand_label") }}
            </button>
          </template>
          <ProtocolOptions
            v-if="protocol.attributes && protocol.attributes.urls"
            :protocol="protocol"
            @protocol:delete_steps="deleteSteps"
            :canDeleteSteps="steps.length > 0 && urls.delete_steps_url !== null"
          />
          <button class="btn btn-light icon-btn" data-toggle="modal" data-target="#print-protocol-modal" tabindex="0">
            <span class="sn-icon sn-icon-printer" aria-hidden="true"></span>
          </button>
          <a v-if="steps.length > 0 && urls.reorder_steps_url"
            class="btn btn-light icon-btn"
            data-toggle="modal"
            @click="startStepReorder"
            @keyup.enter="startStepReorder"
            :class="{'disabled': steps.length == 1}"
            tabindex="0" >
              <i class="sn-icon sn-icon-sort" aria-hidden="true"></i>
          </a>
        </div>
      </div>
    </div>
    <div id="protocol-content" class="protocol-content collapse in" aria-expanded="true">
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
          />
          <span v-else>
            {{ protocol.attributes.name }}
          </span>
        </div>
        <ProtocolMetadata v-if="protocol.attributes && protocol.attributes.in_repository" :protocol="protocol" @update="updateProtocol" @publish="startPublish"/>
        <div :class="inRepository ? 'protocol-section protocol-information' : ''">
          <div v-if="inRepository" id="protocol-description" class="protocol-section-header">
            <div class="protocol-description-container">
              <a class="protocol-section-caret" role="button" data-toggle="collapse" href="#protocol-description-container" aria-expanded="false" aria-controls="protocol-description-container">
                <i class="sn-icon sn-icon-right"></i>
                <span id="protocolDescriptionLabel" class="protocol-section-title">
                  <h2>
                    {{ i18n.t("protocols.header.protocol_description") }}
                  </h2>
                </span>
              </a>
            </div>
          </div>
          <div id="protocol-description-container" :class=" inRepository ? 'protocol-description collapse in' : ''" >
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
            <div v-else-if="protocol.attributes.description_view" v-html="protocol.attributes.description_view"></div>
            <div v-else class="empty-protocol-description">
              {{ i18n.t("protocols.no_text_placeholder") }}
            </div>
          </div>
        </div>
      </div>
      <div :class="inRepository ? 'protocol-section protocol-steps-section protocol-information' : ''">
        <div v-if="inRepository" id="protocol-steps" class="protocol-section-header">
          <div class="protocol-steps-container">
            <a class="protocol-section-caret" role="button" data-toggle="collapse" href="#protocol-steps-container" aria-expanded="false" aria-controls="protocol-steps-container">
              <i class="sn-icon sn-icon-right"></i>
              <span id="protocolStepsLabel" class="protocol-section-title">
                <h2>
                  {{ i18n.t("protocols.header.protocol_steps") }}
                </h2>
              </span>
            </a>
          </div>
        </div>
        <div class="sci-divider my-4" v-if="!inRepository"></div>
        <div id="protocol-steps-container" :class=" inRepository ? 'protocol-steps collapse in' : ''">
          <div v-if="urls.add_step_url && inRepository" class="py-5 flex flex-row gap-8 justify-between">
            <a
              class="btn btn-secondary"
              :title="i18n.t('protocols.steps.new_step_title')"
              @keyup.enter="addStep(steps.length)"
              @click="addStep(steps.length)"
              tabindex="0">
                <span class="sn-icon sn-icon-new-task" aria-hidden="true"></span>
                <span>{{ i18n.t("protocols.steps.new_step") }}</span>
            </a>
            <div v-if="steps.length > 0" class="flex justify-between items-center gap-4">
              <button @click="collapseSteps" class="btn btn-secondary flex px-4" tabindex="0">
                {{ i18n.t("protocols.steps.collapse_label") }}
              </button>
              <button @click="expandSteps" class="btn btn-secondary flex px-4" tabindex="0">
                {{ i18n.t("protocols.steps.expand_label") }}
              </button>
              <a v-if="steps.length > 0 && urls.reorder_steps_url"
                class="btn btn-light icon-btn"
                data-toggle="modal"
                @click="startStepReorder"
                @keyup.enter="startStepReorder"
                :class="{'disabled': steps.length == 1}"
                tabindex="0" >
              <i class="sn-icon sn-icon-sort" aria-hidden="true"></i>
          </a>
          </div>
          </div>
          <div class="protocol-steps pb-8">
            <div v-for="(step, index) in steps" :key="step.id" class="step-block">
              <div v-if="index > 0 && urls.add_step_url" class="insert-step" @click="addStep(index)">
                <i class="sn-icon sn-icon-new-task"></i>
              </div>
              <Step
                ref="steps"
                :step.sync="steps[index]"
                @reorder="startStepReorder"
                :inRepository="inRepository"
                :stepToReload="stepToReload"
                :activeDragStep="activeDragStep"
                @step:delete="updateStepsPosition"
                @step:update="updateStep"
                @stepUpdated="refreshProtocolStatus"
                @step:insert="updateStepsPosition"
                @step:elements:loaded="stepToReload = null"
                @step:move_element="reloadStep"
                @step:attachemnts:loaded="stepToReload = null"
                @step:move_attachment="reloadStep"
                @step:drag_enter="dragEnter"
                :reorderStepUrl="steps.length > 1 ? urls.reorder_steps_url : null"
                :assignableMyModuleId="protocol.attributes.assignable_my_module_id"
              />
            </div>
            <div v-if="steps.length > 0 && urls.add_step_url && inRepository" class="py-5">
              <a
                class="btn btn-secondary"
                :title="i18n.t('protocols.steps.new_step_title')"
                @keyup.enter="addStep(steps.length)"
                @click="addStep(steps.length)"
                tabindex="0">
                  <span class="sn-icon sn-icon-new-task" aria-hidden="true"></span>
                  <span>{{ i18n.t("protocols.steps.new_step") }}</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
    <ReorderableItemsModal v-if="reordering"
      :title="i18n.t('protocols.reorder_steps.modal.title')"
      :items="steps"
      :includeNumbers="true"
      @reorder="updateStepOrder"
      @close="closeStepReorderModal"
    />
    <PublishProtocol v-if="publishing"
      :protocol="protocol"
      @publish="publishProtocol"
      @cancel="closePublishModal"
    />
    <clipboardPasteModal v-if="showClipboardPasteModal"
                         :image="pasteImages"
                         :objects="steps"
                         :objectType="'step'"
                         :selectedObjectId="firstObjectInViewport()"
                         @files="uploadFilesToStep"
                         @cancel="showClipboardPasteModal = false"
    />
  </div>
</template>

 <script>
  import InlineEdit from '../shared/inline_edit.vue'
  import Step from './step'
  import ProtocolMetadata from './protocolMetadata'
  import ProtocolOptions from './protocolOptions'
  import Tinymce from '../shared/tinymce.vue'
  import ReorderableItemsModal from '../shared/reorderable_items_modal.vue'
  import PublishProtocol from './modals/publish_protocol.vue'
  import clipboardPasteModal from '../shared/content/attachments/clipboard_paste_modal.vue'
  import AssetPasteMixin from '../shared/content/attachments/mixins/paste.js'

  import UtilsMixin from '../mixins/utils.js'
  import stackableHeadersMixin from '../mixins/stackableHeadersMixin';
  import moduleNameObserver from '../mixins/moduleNameObserver';

  export default {
    name: 'ProtocolContainer',
    props: {
      protocolUrl: {
        type: String,
        required: true
      }
    },
    components: { Step, InlineEdit, ProtocolOptions, Tinymce, ReorderableItemsModal, ProtocolMetadata, PublishProtocol, clipboardPasteModal},
    mixins: [UtilsMixin, stackableHeadersMixin, moduleNameObserver, AssetPasteMixin],
    computed: {
      inRepository() {
        return this.protocol.attributes.in_repository
      },
      linked() {
        return this.protocol.attributes.linked;
      },
      urls() {
        return this.protocol.attributes.urls || {}
      },
    },
    data() {
      return {
        protocol: {
          attributes: {}
        },
        steps: [],
        reordering: false,
        publishing: false,
        stepToReload: null,
        activeDragStep: null
      }
    },
    mounted() {
      $.get(this.protocolUrl, (result) => {
        this.protocol = result.data;
        this.$nextTick(() => {
          this.refreshProtocolStatus();
          if (!this.inRepository) {
            window.addEventListener('scroll', this.initStackableHeaders, false);
            this.initStackableHeaders();
          }
        });
        $.get(this.urls.steps_url, (result) => {
          this.steps = result.data
        })
      });
    },
    beforeUnmount() {
      if (!this.inRepository) {
        window.removeEventListener('scroll', this.initStackableHeaders, false);
      }
    },
    methods: {
      getHeader() {
        return this.$refs.header;
      },
      reloadStep(step) {
        this.stepToReload = step;
      },
      collapseSteps() {
        $('.step-container .collapse').collapse('hide')
      },
      expandSteps() {
        $('.step-container .collapse').collapse('show')
      },
      deleteSteps() {
        $.post(this.urls.delete_steps_url, () => {
          this.steps = []
        }).fail(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')
        })
      },
      refreshProtocolStatus() {
        if (this.inRepository) return
        // legacy method from app/assets/javascripts/my_modules/protocols.js
        refreshProtocolStatusBar();

        // Update protocol options drowpdown for linked tasks
        this.refreshProtocolDropdownOptions();
      },
      refreshProtocolDropdownOptions() {
        if (!this.linked && this.inRepository) return

        $.get(this.protocolUrl, (result) => {
          this.protocol.attributes.urls = result.data.attributes.urls;
        });
      },
      updateProtocol(attributes) {
        this.protocol.attributes = attributes
      },
      updateName(newName) {
        this.protocol.attributes.name = newName;
        $.ajax({
          type: 'PATCH',
          url: this.urls.update_protocol_name_url,
          data: { protocol: { name: newName } },
          success: () => {
            this.refreshProtocolStatus();
          }
        });
      },
      updateDescription(protocol) {
        this.protocol.attributes = protocol.attributes
        this.refreshProtocolStatus();
      },
      addStep(position) {
        $.post(this.urls.add_step_url, {position: position}, (result) => {
          result.data.newStep = true
          this.updateStepsPosition(result.data);

          // scroll to bottom if step was appended at the end
          if(position === this.steps.length - 1) {
            this.$nextTick(() => this.scrollToBottom());
          }
          this.refreshProtocolStatus();
        }).fail((data) => {
          HelperModule.flashAlertMsg(data.responseJSON.error ? Object.values(data.responseJSON.error).join(', ') : I18n.t('errors.general'), 'danger');
        })
      },
      updateStepsPosition(step, action = 'add') {
        let position = step.attributes.position;
        if (action === 'delete') {
          this.steps.splice(position, 1)
        }
        let unordered_steps = this.steps.map( s => {
          if (s.attributes.position >= position) {
            if (action === 'add') {
              s.attributes.position += 1;
            } else {
              s.attributes.position -= 1;
            }
          }
          return s;
        })
        if (action === 'add') {
          unordered_steps.push(step);
        }
        this.reorderSteps(unordered_steps)
      },
      updateStep(attributes) {
        this.steps[attributes.position].attributes = {
          ...this.steps[attributes.position].attributes,
          ...attributes
        };
        this.refreshProtocolStatus();
      },
      reorderSteps(steps) {
        this.steps = steps.sort((a, b) => a.attributes.position - b.attributes.position);
        this.refreshProtocolStatus();
      },
      updateStepOrder(orderedSteps) {
        orderedSteps.forEach((step, position) => {
          let index = this.steps.findIndex((e) => e.id === step.id);
          this.steps[index].attributes.position = position;
        });

        let stepPositions =
          {
            step_positions: this.steps.map(
              (step) => [step.id, step.attributes.position]
            )
          };

        $.ajax({
          type: "POST",
          url: this.protocol.attributes.urls.reorder_steps_url,
          data: JSON.stringify(stepPositions),
          contentType: "application/json",
          dataType: "json",
          error: (() => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')),
          success: (() => this.reorderSteps(this.steps))
        });
      },
      startStepReorder() {
        this.reordering = true;
      },
      closeStepReorderModal() {
        this.reordering = false;
      },
      startPublish() {
        $.ajax({
          type: "GET",
          url: this.urls.version_comment_url,
          contentType: "application/json",
          dataType: "json",
          success: (result) => {
            this.protocol.attributes.version_comment = result.version_comment;
            this.publishing = true;
          }
        });
      },
      closePublishModal() {
        this.publishing = false;
      },
      scrollToBottom() {
        window.scrollTo(0, document.body.scrollHeight);
      },
      publishProtocol(comment) {
        this.protocol.attributes.version_comment = comment;
        $.post(this.urls.publish_url, {version_comment: comment, view: 'show'})
      },
      scrollTop() {
        window.scrollTo(0, 0);
        setTimeout(() => {
          $('.my_module-name .view-mode').trigger('click');
          $('.my_module-name .input-field').focus();
        }, 300)
      },
      dragEnter(id) {
        this.activeDragStep = id;
      },
      uploadFilesToStep(file, stepId) {
        this.$refs.steps.find(child => child.step?.id == stepId).uploadFiles(file);
      },
      firstObjectInViewport() {
        let step = $('.step-container:not(.locked)').toArray().find(element => {
          const { top, bottom } = element.getBoundingClientRect()
          return bottom > 0 && top < window.innerHeight
        })
        return step ? step.dataset.id : null
      }
    }
  }
 </script>
