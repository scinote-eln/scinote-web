<template>
  <div class="relative leading-5 h-full flex items-center gap-2 truncate">
    <div class="h-10 w-10 p-0.5 bg-sn-light-grey rounded-sm shrink-0">
      <img :src="params.data.workflow_img" class="max-h-9 max-w-[36px]">
    </div>
    <a :href="params.data.urls.show" class="hover:no-underline truncate">{{ params.data.name  }}</a>
  </div>
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
