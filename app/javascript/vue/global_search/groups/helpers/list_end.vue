<template>
  <div class="flex flex-col gap-6 mt-6">
    <div class="flex items-center mb-6">
      <p class="text-sm text-sn-blue flex items-center gap-3 m-auto px-4 py-2 rounded bg-sn-super-light-blue">
        <span class="sn-icon sn-icon-flag"></span>
        <span>{{ i18n.t('search.index.reached_end') }}</span>
      </p>
    </div>
  </div>
</template>

<script>

export default {
  name: 'ListEnd'
};
</script>
