<template>
  <div v-if="option" class="flex items-center gap-2">
    <i v-if="option[2].shared" class="sn-icon sn-icon-users" />
    <span :title="option[1]" class="truncate">{{ option[1] }}</span>
  </div>
</template>

<script>
export default {
  name: 'RepositoryRenderer',
  props: {
    option: {
      type: Array,
      required: true
    }
  }
};
</script>
