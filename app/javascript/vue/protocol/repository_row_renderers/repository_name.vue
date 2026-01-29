<template>
  <span v-if="!params.data.row_code"></span>
  <span v-else-if="!params.data.repository_name" class="text-sn-grey-700">
    <i class="sn-icon sn-icon-locked-task mr-1"></i>
    {{ this.i18n.t('protocols.repository_rows.table.private_inventory') }}
  </span>
  <a v-else
    class="hover:no-underline"
    :href="params.data.repository_url"
    :title="params.data.repository_name"
    target="_blank"
  >
    <i class="sn-icon sn-icon-open mr-1"></i>
    {{ params.data.repository_name }}
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
