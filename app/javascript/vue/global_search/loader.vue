<template>
  <div class="flex flex-col">
    <div v-for="_count in loaderRows"
        class="flex items-center no-wrap border-0 gap-2 py-2 border-b border-solid border-sn-light-grey gap-x-8"
      >
      <div class="w-[500px] grow-1 h-6">
        <div class="h-full w-80 animate-skeleton rounded mr-auto"></div>
      </div>
      <div class="w-24 max-w-24 animate-skeleton rounded h-6"></div>
      <div class="w-44 max-w-44 animate-skeleton rounded h-6"></div>
      <div class="w-44 max-w-44 animate-skeleton rounded h-6"></div>
      <div class="w-56 max-w-56 animate-skeleton rounded h-6"></div>
      <div class="w-96 max-w-96 animate-skeleton rounded h-6"></div>
    </div>
  </div>
</template>

<script>

export default {
  name: 'Loader',
  props: {
    loaderRows: { type: Number, default: 0 },
  }
};
</script>
