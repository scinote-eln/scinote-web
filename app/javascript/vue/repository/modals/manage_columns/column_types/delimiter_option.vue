<template>
  <div v-if="option" class="flex items-center gap-2">
    <span class="text-xl leading-none w-5 text-center shrink-0">{{ option[2].icon }}</span>
    <span class="truncate">{{ option[1] }}</span>
  </div>
</template>

<script>
export default {
  name: 'DelimiterOption',
  props: {
    option: {
      type: Array,
      required: true
    }
  }
};
</script>
