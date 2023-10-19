<template>
  <vue-resizable
    ref="vueResizable"
    :max-width="400"
    :min-width="208"
    width="auto"
    height="100%"
    :active="['r']"
    @resize:start="onResizeStart"
    @resize:move="onResizeMove"
    @resize:end="onResizeEnd"
  >
    <div class="ml-4 h-full border rounded relative bg-sn-white flex flex-col right-0 absolute navigator-container">
      <div class="px-3 py-2.5 flex items-center relative leading-4">
        <i class="sn-icon sn-icon-navigator"></i>
        <div class="font-bold text-base pl-3">
          {{ i18n.t('navigator.title') }}
        </div>
        <i @click="$emit('navigator:colapse')" class="sn-icon sn-icon-close ml-auto cursor-pointer absolute right-2.5 top-2.5"></i>
      </div>
      <perfect-scrollbar @ps-scroll-y="onScrollY" @ps-scroll-x="onScrollX" ref="scrollContainer" class="grow py-2 relative px-2 scroll-container">
        <NavigatorItem v-for="item in sortedMenuItems"
                      :key="item.id"
                      :currentItemId="currentItemId"
                      :item="item"
                      :firstLevel="true"
                      :reloadCurrentLevel="reloadCurrentLevel"
                      :paddingLeft="0"
                      :reloadChildrenLevel="reloadChildrenLevel"
                      :archived="archived" />
      </perfect-scrollbar>
    </div>
  </vue-resizable>
</template>

<script>

import NavigatorItem from './navigator_item.vue'
import VueResizable from 'vue-resizable'
import axios from '../../packs/custom_axios.js';

export default {
  name : 'NavigatorContainer',
  components: {
    NavigatorItem,
    VueResizable
  },
  data() {
    return {
      menuItems: [],
      navigatorCollapsed: false,
      navigatorUrl: null,
      navigatorYScroll: 0,
      navigatorXScroll: 0,
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
      this.$refs.scrollContainer.$el.scrollLeft = this.navigatorXScroll;

      this.changePage();
      if ($(`[navigator-item-id="${this.currentItemId}"]`).length === 0) {
        this.loadTree();
      }
    });
  },
  mounted() {
    this.$refs.vueResizable.style.width = this.getNavigatorWidth()
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
    async loadTree() {
      if (!this.navigatorUrl) return;

      try {
        const { data } = await axios.get(this.navigatorUrl, {
          params: { archived: this.archived }
        });
        this.menuItems = data.items;
      } catch (error) {
        console.error('An error occurred while fetching the data', error);
      }
    },
    onScrollY({target}) {
      this.navigatorYScroll = target.scrollTop;
    },
    onScrollX({target}) {
      this.navigatorXScroll = target.scrollLeft;
    },
    getNavigatorWidth() {
      const computedStyle = getComputedStyle(document.documentElement);
      return computedStyle.getPropertyValue('--navigator-navigation-width').trim();
    },
    onResizeMove(event) {
      document.documentElement.style.setProperty('--navigator-navigation-width', event.width + 'px');
    },
    onResizeStart() {
      document.body.style.cursor = 'url(/images/icon_small/Resize.svg) 0 0, auto';
      $('.sci--layout-navigation-navigator').addClass('!transition-none');
      $('.sci--layout').addClass('!transition-none');
    },
    onResizeEnd(event) {
      document.body.style.cursor = 'default';
      $('.sci--layout-navigation-navigator').removeClass('!transition-none');
      $('.sci--layout').removeClass('!transition-none');
      this.changeNavigatorState(event.width)
    },
    async changeNavigatorState(newWidth) {
      try {
        const navigatorContainer = document.getElementById('sciNavigationNavigatorContainer');
        const stateUrl = navigatorContainer.getAttribute('data-navigator-state-url');
        await axios.post(stateUrl, { width: newWidth });
      } catch (error) {
        console.error('An error occurred while sending the request', error);
      }
    }
  },
}
</script>
