<template>
  <div class="task-protocol">
    <div class="task-section-header">
      <a class="task-section-caret" role="button" data-toggle="collapse" href="#protocol-content" aria-expanded="true" aria-controls="protocol-content">
        <i class="fas fa-caret-right"></i>
        <div class="task-section-title">
          <h2>{{ i18n.t('Protocol') }}</h2>
        </div>
      </a>
      <div class="my-module-protocol-status">
        <!-- protocol status dropdown gets mounted here -->
      </div>
      <div class="sci-btn-group actions-block">
        <a class="btn btn-primary" @click="addStep(steps.length)">
            <span class="fas fa-plus" aria-hidden="true"></span>
            <span>{{ i18n.t("protocols.steps.new_step") }}</span>
        </a>
        <a class="btn btn-default" data-toggle="modal" data-target="#print-protocol-modal">
          <span class="fas fa-print" aria-hidden="true"></span>
          <span>{{ i18n.t("protocols.print.button") }}</span>
        </a>
        <ProtocolOptions v-if="protocol.attributes && protocol.attributes.urls" :protocol="protocol" />
      </div>
    </div>
    <div v-if="protocol.id" id="protocol-content" class="protocol-content collapse in" aria-expanded="true">
      <div class="protocol-description">
        <div class="protocol-name">
          <InlineEdit
            :value="protocol.attributes.name"
            :characterLimit="255"
            :placeholder="i18n.t('my_modules.protocols.protocol_status_bar.enter_name')"
            :allowBlank="true"
            :attributeName="`${i18n.t('Protocol')} ${i18n.t('name')}`"
            @update="updateName"
          />
        </div>
        <Tinymce
          :value="protocol.attributes.description"
          :value_html="protocol.attributes.description_view"
          :placeholder="i18n.t('my_modules.protocols.protocol_status_bar.empty_description_edit_label')"
          :updateUrl="protocolUrl"
          :objectType="'Protocol'"
          :objectId="parseInt(protocol.id)"
          :fieldName="'protocol[description]'"
          :lastUpdated="protocol.attributes.updated_at"
          @update="updateDescription"
        />
      </div>
      <div class="protocol-step-actions">
        <a class="btn btn-default" data-toggle="modal" @click="startStepReorder">
            <span class="fas fa-arrows-alt-v" aria-hidden="true"></span>
            <span>{{ i18n.t("protocols.reorder_steps.button") }}</span>
        </a>
      </div>
      <div class="protocol-steps">
        <template v-for="(step, index) in steps">
          <div class="step-block" :key="step.id">
            <div v-if="index > 0" class="insert-step" @click="addStep(index)">
              <i class="fas fa-plus"></i>
            </div>
            <Step
              :step.sync="steps[index]"
              @reorder="startStepReorder"
              @step:delete="updateStepsPosition"
              @step:update="updateStep"
            />
          </div>
        </template>
      </div>
      <button class="btn btn-primary" @click="addStep(steps.length)">
        <i class="fas fa-plus"></i>
        {{ i18n.t("protocols.steps.new_step") }}
      </button>
    </div>
    <ProtocolModals/>
    <ReorderableItemsModal v-if="reordering"
      :title="i18n.t('protocols.reorder_steps.modal.title')"
      :items="steps"
      :includeNumbers="true"
      @reorder="updateStepOrder"
      @close="closeStepReorderModal"
    />
  </div>
</template>

 <script>
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import Step from 'vue/protocol/step'
  import ProtocolOptions from 'vue/protocol/protocolOptions'
  import ProtocolModals from 'vue/protocol/modals'
  import Tinymce from 'vue/shared/tinymce.vue'
  import ReorderableItemsModal from 'vue/protocol/modals/reorderable_items_modal.vue'

  import UtilsMixin from 'vue/protocol/mixins/utils.js'

  export default {
    name: 'ProtocolContainer',
    props: {
      protocolUrl: {
        type: String,
        required: true
      },
      stepsUrl: {
        type: String,
        required: true
      },
      addStepUrl: {
        type: String,
        required: true
      },
      editable:{
        Boolean,
        required: true
      }
    },
    components: { Step, InlineEdit, ProtocolModals, ProtocolOptions, Tinymce, ReorderableItemsModal },
    mixins: [UtilsMixin],
    data() {
      return {
        protocol: {
          attributes: {}
        },
        steps: {},
        reordering: false
      }
    },
    created() {
      $.get(this.protocolUrl, (result) => {
        this.protocol = result.data;
      });
      $.get(this.stepsUrl, (result) => {
        this.steps = result.data
      })
    },
    methods: {
      refreshProtocolStatus() {
        // legacy method from app/assets/javascripts/my_modules/protocols.js
        refreshProtocolStatusBar();
      },
      updateName(newName) {
        this.protocol.attributes.name = newName;
        this.refreshProtocolStatus();
        $.ajax({
          type: 'PATCH',
          url: this.protocolUrl,
          data: { protocol: { name: newName } }
        });
      },
      updateDescription(protocol) {
        this.protocol.attributes = protocol.data.attributes
      },
      addStep(position) {
        $.post(this.addStepUrl, {position: position}, (result) => {
          this.updateStepsPosition(result.data)
        })
        this.refreshProtocolStatus();
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
        this.steps[attributes.position].attributes = attributes
        this.refreshProtocolStatus();
      },
      reorderSteps(steps) {
        this.steps = steps.sort((a, b) => a.attributes.position - b.attributes.position);
        this.refreshProtocolStatus();
      },
      updateStepOrder(orderedSteps) {
        orderedSteps.forEach((step, position) => {
          let index = this.steps.findIndex((e) => e.id === step.id);
          this.steps[index].attributes.position = position + 1;
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
          error: (() => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger'))
        });

        this.reorderSteps(this.steps);
      },
      startStepReorder() {
        this.reordering = true;
      },
      closeStepReorderModal() {
        this.reordering = false;
      }
    }
  }
 </script>
