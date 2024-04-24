<template>
<div :title="text" class="flex items-center">
  <template v-if="text.length <= endCharacters">
    <div class="shrink-0">
      {{ text }}
    </div>
  </template>
  <template v-else>
    <div class="truncate">
      {{ text.slice(0, endCharacters * -1) }}
    </div>
    <div class="shrink-0">
      {{ text.slice(text.length - endCharacters) }}
    </div>
  </template>
</div>
</template>

<script>
export default {
  name: 'StringWithEllipsis',
  props: {
    text: {
      type: String,
      required: true
    },
    endCharacters: {
      type: Number,
      default: 4
    }
  }
};
</script>
