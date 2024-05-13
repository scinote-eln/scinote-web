<template>
  <div class="contents lg:hidden">
    <div class="px-4 py-2 bg-white h-full" :class="{'sticky top-[68px] z-10': selected}"></div>
    <div
      v-for="column in columnNames"
      :key="column"
      class="truncate px-4  py-2 bg-white text-xs font-bold h-full"
      :class="{'sticky top-[68px] z-10': selected}"
    >{{ column }}</div>
  </div>
</template>

<script>
export default {
  name: 'TableHeader',
  props: {
    columnNames: {
      type: Array,
      required: true
    },
    selected: {
      type: Boolean,
      default: false
    }
  }
};
</script>
