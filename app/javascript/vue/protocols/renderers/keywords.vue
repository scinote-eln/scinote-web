<template>
  <div class="flex items-center gap-2 truncate h-full">
    <div v-for="keyword in params.data.keywords" :key="keyword.id"
         @click="params.dtComponent.setSearchValue(keyword)"
         class="px-2 py-1 rounded-sm bg-sn-super-light-grey gap-1 leading-5 cursor-pointer hover:bg-sn-light-grey">
      {{ keyword }}
    </div>
    <div v-if="params.data.keywords.length === 0">
      —
    </div>
  </div>
</template>

<script>
export default {
  name: 'KeywordsRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
