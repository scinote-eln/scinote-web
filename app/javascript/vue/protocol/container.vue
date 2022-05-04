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
      </div>
      <div class="protocol-steps">
        <template v-for="(step, index) in steps">
          <div class="step-block" :key="step.id">
            <div v-if="index > 0" class="insert-step" @click="addStep(index)">
              <i class="fas fa-plus"></i>
            </div>
            <Step
              :step.sync="steps[index]"
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
  </div>
</template>

 <script>
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import Step from 'vue/protocol/step'
  import ProtocolOptions from 'vue/protocol/protocolOptions'
  import ProtocolModals from 'vue/protocol/modals'

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
    components: { Step, InlineEdit, ProtocolModals, ProtocolOptions },
    data() {
      return {
        protocol: {
          attributes: {}
        },
        steps: {}
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
      }
    }
  }
 </script>
