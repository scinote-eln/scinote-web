<template>
  <a  :href="params.data.urls.show"
      class="flex items-center gap-1 hover:no-underline"
      :class="{
        'pointer-events-none text-sn-grey': !params.data.urls.show
      }"
      :title="params.data.name">
    <i v-if="params.data.folder" class="sn-icon mini sn-icon-mini-folder-left"></i>
    <span class="truncate">{{ params.data.name }}</span>
  </a>
</template>
<script>
export default {
  name: 'NameRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
