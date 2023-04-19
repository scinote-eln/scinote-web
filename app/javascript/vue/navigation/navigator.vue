<template>
  <div class="w-72 h-full border rounded bg-white flex flex-col right-0 absolute">
    <div class="p-3 flex items-center">
      <i class="fas fa-bars p-2 cursor-pointer"></i>
      <div class="font-bold text-base">
        {{ i18n.t('navigator.title') }}
      </div>
      <i @click="$emit('navigator:colapse')" class="fas fa-times ml-auto cursor-pointer"></i>
    </div>
    <div class="grow px-2 py-4">
      <NavigatorItem v-for="item in sortedMenuItems" :key="item.id" :item="item" />
    </div>
  </div>
</template>

<script>

import NavigatorItem from './navigator_item.vue'

export default {
  name : 'NavigatorContainer',
  components: {
    NavigatorItem
  },
  data() {
    return {
      menuItems: [],
      navigatorCollapsed: false
    }
  },
  computed: {
    sortedMenuItems() {

      return this.menuItems.sort((a, b) => a.name - b.name)
    }
  },
  created() {
    this.menuItems = [
      {id: 'p1', name: 'Project 1', url: '/', archive: false, children: [
        {id: 'e1', name: 'Experiment 1', url: '/', archive: false}
      ]},
      {id: 'f1', name: 'Folder', url: '/', archive: false, icon: 'fas fa-folder', children: [
        {id: 'p2', name: 'Project 2', url: '/', archive: false, children: [
          {id: 'e2', name: 'Experiment 2', url: '/', archive: false, children: [
            {id: 't1', name: 'Task', url: '/', archive: false}
        ]}
      ]}
      ]}
    ]
  }
}
</script>
