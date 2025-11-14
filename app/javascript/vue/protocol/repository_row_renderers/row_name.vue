<template>
  <span v-if="!params.data.row_code">
    {{ this.i18n.t('protocols.repository_rows.table.deleted_item') }}
  </span>
  <span v-else-if="!params.data.name" class="text-sn-grey-700">
    <i class="sn-icon sn-icon-locked-task mr-1"></i>
    {{ this.i18n.t('protocols.repository_rows.table.private_item') }}
  </span>
  <span v-else-if="params.data.archived" class="text-sn-grey-700">
    <i class="sn-icon sn-icon-archived mr-1"></i>
    {{ params.data.name }}
  </span>
  <a v-else
    :href="params.data.row_url"
    class="record-info-link hover:no-underline"
    :title="params.data.name"
  >
    {{ params.data.name }}
  </a>
</template>
<script>
export default {
  name: 'RowNameRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
