<template>
  <div class="!w-[300px] rounded bg-sn-super-light-grey gap-4 p-6 flex flex-col h-full">
    <div id="info-component-header">
      <h3 class="modal-title text-sn-dark-grey">{{ params.title }}</h3>
    </div>

    <div class="grid grid-flow-row h-fit" v-for="(element, _index) in params.elements" :key="element.id">
      <a v-if="element.linkTo" :href="element.linkTo" target="_blank" class="flex flex-row gap-3 w-fit text-sn-blue hover:no-underline hover:text-sn-blue-hover">
        <button class="btn btn-secondary btn-sm icon-btn hover:!border-sn-light-grey">
          <i :class="element.icon" class="h-fit"></i>
        </button>
        <div class="flex flex-col gap-2 w-fit">
          <div class="text-sn-blue font-bold hover:text-sn-blue-hover my-auto">{{ element.label }}</div>
        </div>
      </a>
      <div v-else class="flex flex-row gap-3">
        <button class="btn btn-secondary btn-sm icon-btn hover:!border-sn-light-grey hover:cursor-auto">
          <i :class="`sn-icon ${element.icon}`" class="h-fit text-sn-dark-grey size-9"></i>
        </button>
        <div class="flex flex-col gap-2 w-52">
          <div class="text-sn-dark-grey font-bold">{{ element.label }}</div>
          <div class="text-sn-dark-grey">{{ element.subtext }}</div>
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
