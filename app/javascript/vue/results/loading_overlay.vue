<template>
  <div>
    <div class="flex flex-col gap-8">
      <div v-for="_count in loaderResults"
          class="flex flex-col no-wrap gap-4 py-2"
        >
        <div class="h-10 w-full max-w-40 animate-skeleton rounded mr-auto"></div>
        <div class="w-full animate-skeleton rounded h-64"></div>
        <div class="flex items-center gap-6 flex-wrap">
          <div class="w-48 h-64 animate-skeleton rounded"></div>
          <div class="w-48 h-64 animate-skeleton rounded"></div>
          <div class="w-48 h-64 animate-skeleton rounded"></div>
          <div class="w-48 h-64 animate-skeleton rounded"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    loaderResults: {
      type: Number,
      default: 3
    }
  }
};
</script>