<template>
  <div class="w-[216px] ml-6 h-full border rounded relative bg-sn-white flex flex-col right-0 absolute navigator-container">
    <div class="px-3 py-2 flex items-center relative leading-4">
      <i class="sn-icon sn-icon-navigator"></i>
      <div class="font-bold text-base pl-2">
        {{ i18n.t('navigator.title') }}
      </div>
      <i @click="$emit('navigator:colapse')" class="sn-icon sn-icon-close ml-auto cursor-pointer absolute right-3 top-2"></i>
    </div>
    <perfect-scrollbar @ps-scroll-y="onScroll" ref="scrollContainer" class="grow py-4 relative px-3">
      <NavigatorItem v-for="item in sortedMenuItems"
                     :key="item.id"
                     :currentItemId="currentItemId"
                     :item="item"
                     :firstLevel="true"
                     :reloadCurrentLevel="reloadCurrentLevel"
                     :reloadChildrenLevel="reloadChildrenLevel"
                     :archived="archived" />
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
      navigatorYScroll: 0,
      currentItemId: null,
      archived: null
    }
  },
  props: {
    reloadCurrentLevel: Boolean,
    reloadChildrenLevel: Boolean
  },
  computed: {
    sortedMenuItems() {
      return this.menuItems.sort((a, b) => {
        if (a.name.toLowerCase() < b.name.toLowerCase()) {
          return -1;
        }
        if (a.name.toLowerCase() > b.name.toLowerCase()) {
          return 1;
        }
        return 0;
      });
    }
  },
  created() {
    this.changePage();
    $(document).on('turbolinks:load', () => {
      this.$refs.scrollContainer.$el.scrollTop = this.navigatorYScroll;
      this.changePage();
      if ($(`[navigator-item-id="${this.currentItemId}"]`).length === 0) {
        this.loadTree();
      }
    });
  },
  watch: {
    archived() {
      this.loadTree();
    },
    reloadCurrentLevel: function() {
      if (this.reloadCurrentLevel && (
            this.currentItemId.length == 0 ||
            this.menuItems.filter(item => item.id == this.currentItemId)
          )) {
        this.loadTree();
      }
    }
  },
  methods: {
    changePage() {
      this.navigatorUrl = $('#active_navigator_url').val();
      this.currentItemId = $('#active_navigator_item').val();
      this.archived = $('#active_navigator_archived').val() === 'true';
    },
    loadTree() {
      if (!this.navigatorUrl) return;

      $.get(this.navigatorUrl, {archived: this.archived}, (data) => {
        this.menuItems = [];
        this.$nextTick(() => {
          this.menuItems = data.items;
        });
      })
    },
    onScroll({target}) {
      this.navigatorYScroll = target.scrollTop;
    },
  },
}
</script>
