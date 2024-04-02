<template>
  <div class="!w-[300px] rounded bg-sn-super-light-grey gap-4 p-6 flex flex-col h-full">
    <div id="info-component-header">
      <h3 class="modal-title text-sn-dark-grey">{{ params.componentTitle }}</h3>
    </div>

    <div class="grid grid-flow-row h-fit" v-for="(step, _index) in params.elements" :key="step.id">
      <a v-if="step.linkTo" :href="step.linkTo" target="_blank" class="flex flex-row gap-3 w-fit text-sn-blue hover:no-underline hover:text-sn-blue-hover">
        <button class="btn btn-secondary btn-sm icon-btn hover:!border-sn-light-grey">
          <i :class="step.icon" class="h-fit"></i>
        </button>
        <div class="flex flex-col gap-2 w-fit">
          <div class="text-sn-blue font-bold hover:text-sn-blue-hover my-auto">{{ step.label }}</div>
        </div>
      </a>
      <div v-else class="flex flex-row gap-3">
        <button class="btn btn-secondary btn-sm icon-btn hover:!border-sn-light-grey hover:cursor-auto">
          <i :class="step.icon" class="h-fit text-sn-dark-grey size-9"></i>
        </button>
        <div class="flex flex-col gap-2 w-52">
          <div class="text-sn-dark-grey font-bold">{{ step.label }}</div>
          <div class="text-sn-dark-grey">{{ step.subtext }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'InfoComponent',
  props: {
    params: {
      type: Object,
      required: true
    }
  }
};
</script>
