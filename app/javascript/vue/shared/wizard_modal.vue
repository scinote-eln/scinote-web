<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog" data-backdrop="static" data-keyboard="false">
    <div class="modal-dialog !w-[900px]" role="document">
      <div class="modal-content !p-0 grid grid-cols-3">
        <div class="bg-sn-super-light-grey p-6 mb-1.5">
          <div class="flex justify-start mb-1.5">
            <h3 class="modal-title">{{ config.title }}</h3>
          </div>
          <div v-if="config.subtitle" class="text-sn-dark-grey">
            {{ config.subtitle }}
          </div>
          <div class="flex flex-col mt-4">
            <div v-for="(step, index) in config.steps" :key="step.id">
              <div v-if="index > 0"
                class="ml-0.5 left-4 relative h-8 w-0 border border-r-0 border-solid"
                :class="{
                    '!border-sn-dark-grey': index <= activeStep,
                    '!border-sn-sleepy-grey': index > activeStep
                  }"
              ></div>
              <div class="flex items-center gap-3">
                <div class="rounded bg-white border border-sn-sleepy-grey p-1.5">
                  <i :class="[
                    step.icon,
                    {
                      'text-sn-dark-grey': index <= activeStep,
                      'text-sn-grey': index > activeStep
                    }
                  ]"></i>
                </div>
                <span
                  class="font-bold text-xs"
                  :class="{
                    'text-sn-dark-grey': index <= activeStep,
                    'text-sn-grey': index > activeStep
                  }"
                >
                  {{ step.label }}
                </span>
              </div>
            </div>
          </div>
        </div>
        <div class="col-span-2 p-6 flex flex-col">
          <component
            :is="config.steps[activeStep].component"
            :params="params"
            :wizardComponent="this"
            @close="close"
            @back="activeStep -= 1"
            @next="activeStep += 1"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from './modal_mixin';

export default {
  name: 'WizardModal',
  props: {
    params: {
      type: Object,
      required: true
    },
    config: {
      type: Object,
      required: true
    }
  },
  mixins: [modalMixin],
  data() {
    return {
      activeStep: 0
    };
  }
};
</script>
