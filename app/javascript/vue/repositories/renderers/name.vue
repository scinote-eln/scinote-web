<template>
  <a class="hover:no-underline flex items-center gap-1"
     :title="params.data.name"
     :class="{
        'pointer-events-none text-sn-grey': !params.data.urls.show
      }"
     :href="params.data.urls.show"
  >
    <span class="truncate">
      <i v-if="params.data.shared || params.data.ishared" class="fas fa-users"></i>
      {{ params.data.name }}
    </span>
  </a>
</template>

<script>
export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  }
};
</script>
