<template>
  <div class="relative leading-5 h-full flex items-center gap-2 truncate">
    <div class="h-10 w-10 p-0.5 bg-sn-light-grey rounded-sm shrink-0 relative">
      <div v-if="imageLoading" class="flex absolute top-0 items-center justify-center w-full flex-grow h-full z-10">
        <img src="/images/medium/loading.svg" alt="Loading" class="w-4 h-4" />
      </div>
      <img v-else-if="!hasError" :src="workflow_img" @error="hasError = true" class="max-h-9 max-w-[36px]">
    </div>
    <a :href="params.data.urls.show" class="hover:no-underline truncate"
        :title="params.data.name">
      {{ params.data.name  }}
    </a>
  </div>
</template>

<script>

import workflowImgMixin from '../workflow_img_mixin.js';

export default {
  name: 'NameRenderer',
  props: {
    params: {
      required: true
    }
  },
  mixins: [workflowImgMixin]
};
</script>
