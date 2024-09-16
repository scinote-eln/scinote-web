<template>
  <span>
    <span v-if="params.data.hidden" class="text-sn-grey-700">
      <i class="sn-icon sn-icon-locked-task"></i>
      {{ i18n.t('storage_locations.show.hidden') }}
    </span>
    <a
      :href="params.data.row_url"
      class="record-info-link"
      :title="params.data.row_name"
    >
      {{ params.data.row_name }}
    </a>
  </span>
</template>

<script>
export default {
  name: 'ItemNameRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
