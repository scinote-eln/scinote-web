<template>
  <div class="flex items-center gap-2">
    <div
      class="w-4 h-4 rounded-full"
      :class="{ 'bg-sn-grey-500': params.data.status.light_color }"
      :style="!params.data.status.light_color && { backgroundColor: params.data.status.color }"
    ></div>
    <span class="truncate">
      {{ params.data.status.name }}
    </span>
  </div>
</template>

<script>
export default {
  name: 'StatusRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
