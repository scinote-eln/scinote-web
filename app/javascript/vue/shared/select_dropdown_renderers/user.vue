<template>
  <div v-if="option" class="flex items-center gap-2">
    <img :src="option[2].avatar_url" class="rounded-full w-6 h-6" />
    <span :title="option[1]" class="truncate">{{ option[1] }}</span>
  </div>
</template>

<script>
export default {
  name: 'UserRenderer',
  props: {
    option: {
      type: Array,
      required: true
    }
  }
};
</script>
