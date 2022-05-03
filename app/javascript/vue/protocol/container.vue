<template>
  <div class="task-protocol">
    <div class="task-section-header">
      <a class="task-section-caret" role="button" data-toggle="collapse" href="#protocol-content" aria-expanded="true" aria-controls="protocol-content">
        <i class="fas fa-caret-right"></i>
        <div class="task-section-title">
          <h2>{{ i18n.t('Protocol') }}</h2>
        </div>
        <span v-if="protocol.linked" class="status-label linked">
          [{{ protocol.name }}]
        </span>
        <span class="status-label" v-else>
          [{{ i18n.t('my_modules.protocols.protocol_status_bar.unlinked') }}]
        </span>
      </a>
      <div class="sci-btn-group actions-block">
        <a class="btn btn-primary" @click="addStep(steps.length)">
            <span class="fas fa-plus" aria-hidden="true"></span>
            <span>New step</span>
        </a>
        <a class="btn btn-default" data-toggle="modal" data-target="#print-protocol-modal">
          <span class="fas fa-print" aria-hidden="true"></span>
          <span>Print</span>
        </a>
        <div class="dropdown sci-dropdown">
          <button class="btn btn-secondary dropdown-toggle" type="button" id="dropdownProtocolOptions" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            <span class="fas fa-cog"></span>
            <span>Protocol options</span>
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdownProtocolOptions">
            <li>
              <a>
                <span class="fas fa-edit"></span>
                <span>Load from repository</span>
              </a>
            </li>
            <li>
              <a>
                <span class="fas fa-download"></span>
                <span>Import protocol</span>
              </a>
            </li>
            <li>
              <a>
                <span class="fas fa-upload"></span>
                <span>Export protocol</span>
              </a>
            </li>
            <li>
              <a>
                <span class="fas fa-save"></span>
                <span>Save to repository</span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <div v-if="protocol.id" id="protocol-content" class="protocol-content collapse in" aria-expanded="true">
      <div class="protocol-description">
        <div class="protocol-name">
          <InlineEdit
            :value="protocol.name"
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
  </div>
</template>

 <script>
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import Step from 'vue/protocol/step'

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
    components: { Step, InlineEdit },
    data() {
      return {
        protocol: {},
        steps: {}
      }
    },
    created() {
      $.get(this.protocolUrl, (data) => {
        this.protocol = data;
      });
      $.get(this.stepsUrl, (result) => {
        this.steps = result.data
      })
    },
    methods: {
      updateName(newName) {
        this.protocol.name = newName;
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
      },
      reorderSteps(steps) {
        this.steps = steps.sort((a, b) => a.attributes.position - b.attributes.position);
      }
    }
  }
 </script>
