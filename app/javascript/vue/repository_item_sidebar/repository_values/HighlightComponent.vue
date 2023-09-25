<template>
  <div id="highlight-container" class="w-[1px] h-[130px] flex flex-col justify-evenly bg-sn-light-grey">
    <div v-for="(item, index) in itemsToCreate">
      <div :key="index" :id="item" class="w-[5px] h-[28px] rounded-[11px]"></div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HighlightComponent',
  props: {
    itemsToCreate: Array
  }
}
</script>
