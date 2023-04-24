<template>
  <div class="w-72 h-full border rounded bg-white flex flex-col right-0 absolute navigator-container">
    <div class="p-3 flex items-center">
      <i class="fas fa-bars p-2 cursor-pointer"></i>
      <div class="font-bold text-base">
        {{ i18n.t('navigator.title') }}
      </div>
      <i @click="$emit('navigator:colapse')" class="fas fa-times ml-auto cursor-pointer"></i>
    </div>
    <perfect-scrollbar class="grow px-2 py-4 relative">
      <NavigatorItem v-for="item in sortedMenuItems" :key="item.id" :currentItemId="currentItemId" :item="item" />
    </perfect-scrollbar>
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
      navigatorCollapsed: false,
      navigatorUrl: null,
      currentItemId: null
    }
  },
  computed: {
    sortedMenuItems() {
      return this.menuItems.sort((a, b) => a.name - b.name)
    }
  },
  created() {
    this.changePage();
    this.loadTree();

    $(document).on('turbolinks:load', () => {
      this.changePage();
      if ($(`[navigator-item-id="${this.currentItemId}"]`).length === 0) {
        this.loadTree();
      }
    });
  },
  methods: {
    changePage() {
      this.navigatorUrl = $('#active_navigator_url').val();
      this.currentItemId = $('#active_navigator_item').val();
    },
    loadTree() {
      if (!this.navigatorUrl) return;

      $.get(this.navigatorUrl, {archived: false}, (data) => {
        this.menuItems = data.items
      })
    }
  },
}
</script>
