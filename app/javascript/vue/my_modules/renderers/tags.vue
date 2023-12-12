<template>

  <span v-if="params.data.tags > 0" @click.stop="openModal" class="text-sn-blue cursor-pointer">
    {{ params.data.tags }}
  </span>
  <span v-else-if="params.data.permissions.manage_tags" @click.stop="openModal" class="text-sn-blue cursor-pointer">
    {{ i18n.t('experiments.table.add_tag') }}
  </span>
  <span v-else>{{ i18n.t('experiments.table.not_set') }}</span>
</template>

<script>

export default {
  name: 'TagsRenderer',
  props: {
    params: {
      required: true
    }
  },
  methods: {
    openModal() {
      this.params.dtComponent.$emit('editTags', null, [this.params.data]);
    }
  }
};
</script>
