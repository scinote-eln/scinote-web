<template>
  <div class="sn-color-primary pl-7 pt-4 flex items-center flex-wrap">
    <div class="w-5 mr-2 flex justify-start">
      <i v-if="haveChildren"
        class="fas cursor-pointer"
        :class="{'fa-chevron-right': !childrenOpen, 'fa-chevron-down': childrenOpen }"
        @click="childrenOpen = !childrenOpen"></i>
    </div>
    <i v-if="item.icon" class="mr-2" :class="item.icon"></i>
    {{ item.name }}
    <div v-if="childrenOpen" class="basis-full">
      <NavigatorItem v-for="item in sortedMenuItems" :key="item.id" :item="item" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'NavigatorItem',
  props: {
    item: Object
  },
  data: function() {
    return {
      childrenOpen: false
    }
  },
  computed: {
    haveChildren: function() {
      return this.item.children && this.item.children.length > 0
    },
    sortedMenuItems: function() {
      if (!this.haveChildren) return []
      return this.item.children.sort((a, b) => a.name - b.name)
    }
  },
}
</script>
