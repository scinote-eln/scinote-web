<template>
    <div class="task-protocol">
      <div class="task-section-header">
        <a class="task-section-caret" role="button" data-toggle="collapse" href="#protocol-content" aria-expanded="true" aria-controls="protocol-content">
          <i class="fas fa-caret-right"></i>
          <div class="task-section-title">
            <h2>{{ i18n.t('Protocol') }}</h2>
          </div>
        </a>
      </div>
      <div id="protocol-content" class="protocol-content collapse in" aria-expanded="true">
        <div class="protocol-description">
          <input type="text" class="inline" :model="protocol.name" :placeholder="i18n.t('my_modules.protocols.protocol_status_bar.enter_name')">
        </div>
        <div class="protocol-steps">
          <template v-for="(step, index) in steps">
            <div class="step-block" :key="step.id">
              <button v-if="index > 0" class="btn btn-primary" @click="addStep(index)">
                <i class="fas fa-plus"></i>
                {{ i18n.t("protocols.steps.new_step") }}
              </button>
              <Step
                :step.sync="steps[index]"
                @step:delete="updateStepsPosition"
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
      }
    },
    components: { Step },
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
      reorderSteps(steps) {
        this.steps = steps.sort((a, b) => a.attributes.position - b.attributes.position);
      }
    }
  }
 </script>
