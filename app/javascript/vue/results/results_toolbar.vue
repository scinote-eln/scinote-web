<template>
  <div class="result-toolbar p-3 flex justify-between rounded-md bg-sn-white">
    <div class="result-toolbar__left">
      <button class="btn btn-secondary">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('my_modules.results.add_label') }}
      </button>
    </div>
    <div class="result-toolbar__right flex items-center">
      <button class="btn btn-secondary mr-3">
        {{ i18n.t('my_modules.results.expand_label') }}
      </button>
      <button class="btn btn-secondary mr-3">
        {{ i18n.t('my_modules.results.collapse_label') }}
      </button>

      <button class="btn btn-light icon-btn mr-3">
        <i class="sn-icon sn-icon-filter"></i>
      </button>
      <button class="btn btn-light icon-btn">
        <i class="sn-icon sn-icon-sort"></i>
      </button>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'ResultsToolbar',
    props: {
      urls: { type: Object, required: true }
    }
  }
</script>
