<template>
  <div class="flex flex-col gap-6">
    <div v-if="!total" class="grid grid-cols-[32px_auto] gap-2.5">
      <div class="h-8 w-8 animate-skeleton rounded"></div>
      <div class="h-8 w-40 animate-skeleton rounded"></div>
    </div>
    <div class="flex flex-col" :class="[`gap-[${loaderGap}px]`]">
      <div v-for="_count in loaderRows"
          class="flex items-center no-wrap border-0 border-b border-solid border-sn-light-grey gap-x-8"
          :class="[`gap-y-[${loaderGap}px]`, `py-[${loaderYPadding}px]`, { 'first:border-t': total }]">
        <div class="w-[500px] grow-1" :class="`h-[${loaderHeight}px]`">
          <div class="h-full w-80 animate-skeleton rounded mr-auto"></div>
        </div>
        <div :class="`h-[${loaderHeight}px]`" class="w-24 max-w-24 animate-skeleton rounded"></div>
        <div :class="`h-[${loaderHeight}px]`" class="w-44 max-w-44 animate-skeleton rounded"></div>
        <div :class="`h-[${loaderHeight}px]`" class="w-44 max-w-44 animate-skeleton rounded"></div>
        <div :class="`h-[${loaderHeight}px]`" class="w-56 max-w-56 animate-skeleton rounded"></div>
        <div :class="`h-[${loaderHeight}px]`" class="w-96 max-w-96 animate-skeleton rounded"></div>
      </div>
    </div>
    <div v-if="reachedEnd" class="flex items-center mb-6">
      <p class="text-sm text-sn-blue flex items-center gap-3 m-auto">
        <span class="sn-icon sn-icon-flag"></span>
        <span>{{ i18n.t('search.index.reached_end') }}</span>
      </p>
    </div>
  </div>
</template>

<script>

export default {
  name: 'Loader',
  props: {
    total: { type: Number, default: 0 },
    loaderRows: { type: Number, default: 0 },
    loaderHeight: { type: Number, required: true },
    loaderGap: { type: Number, required: true },
    loaderYPadding: { type: Number, required: true },
    reachedEnd: { type: Boolean }
  }
};
</script>
