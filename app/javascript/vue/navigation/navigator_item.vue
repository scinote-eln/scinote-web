<template>
  <div>
    <div class="text-sn-blue w-full flex justify-center flex-col menu-item rounded"
        :class="{ 'bg-sn-super-light-blue active': activeItem }"
        :style="{ 'padding-left': paddingLeft + 'px', 'min-width': (paddingLeft + 182) + 'px' }"
        :navigator-item-id="item.id"
    >
      <div class="min-w-[182px] py-1.5 px-1 flex items-center whitespace-nowrap" :title="this.itemToolTip">
        <div class="w-6 h-6 flex justify-start shrink-0 mr-2">
          <i v-if="hasChildren"
            class="sn-icon cursor-pointer"
            :class="{'sn-icon-right': !childrenExpanded, 'sn-icon-down': childrenExpanded }"
            @click="toggleChildren"></i>
        </div>
        <i v-if="itemIcon" class="mr-1" :class="itemIcon"></i>
        <a :href="item.url"
            class="text-ellipsis overflow-hidden hover:no-underline pr-3"
            :class="{
              'text-sn-science-blue-hover': (!item.archived && archived),
              'no-hover': (!item.archived && archived),
              'disabled-link': item.disabled
            }">
          <template v-if="item.archived">(A)</template>
          {{ item.name }}
        </a>
      </div>
    </div>
    <div class="basis-full" :class="{'hidden': !childrenExpanded}">
      <NavigatorItem v-for="item in sortedMenuItems"
                    @item:expand="treeExpand"
                    :key="item.id"
                    :currentItemId="currentItemId"
                    :paddingLeft="24 + paddingLeft"
                    :reloadCurrentLevel="reloadCurrentLevel"
                    :reloadChildrenLevel="reloadChildrenLevel"
                    :reloadExpandedChildrenLevel="reloadExpandedChildrenLevel"
                    :item="item"
                    :archived="archived" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'NavigatorItem',
  props: {
    firstLevel: {
      type: Boolean,
      default: false
    },
    item: Object,
    currentItemId: String,
    archived: Boolean,
    paddingLeft: Number,
    reloadCurrentLevel: Boolean,
    reloadChildrenLevel: Boolean,
    reloadExpandedChildrenLevel: Boolean
  },
  data() {
    return {
      childrenExpanded: false,
      childrenLoaded: false,
      children: []
    };
  },
  computed: {
    hasChildren() {
      if (this.item.disabled) return false;
      if (this.item.has_children) return true;
      if (this.children && this.children.length > 0) return true;
      return false;
    },
    sortedMenuItems() {
      if (!this.children) return [];

      return this.children.sort((a, b) => {
        if (a.name.toLowerCase() < b.name.toLowerCase()) {
          return -1;
        }
        if (a.name.toLowerCase() > b.name.toLowerCase()) {
          return 1;
        }
        return 0;
      });
    },
    activeItem() {
      return this.item.id == this.currentItemId;
    },
    itemIcon() {
      switch (this.item.type) {
        case 'folder':
          return 'sn-icon mini sn-icon-mini-folder-left';
        default:
          return null;
      }
    },
    itemToolTip() {
      if (this.item.type == 'folder') return this.item.name;
      return this.i18n.t('sidebar.elements_tooltip', { type: this.i18n.t(`activerecord.models.${this.item.type}`), name: this.item.name });
    }
  },
  created() {
    if (this.item.children) this.children = this.item.children;
  },
  mounted() {
    this.selectItem();
  },
  watch: {
    currentItemId() {
      this.selectItem();
    },
    reloadChildrenLevel() {
      if (this.reloadChildrenLevel && this.item.id == this.currentItemId) {
        this.loadChildren();
      }
    },
    reloadExpandedChildrenLevel() {
      if (this.reloadExpandedChildrenLevel && this.childrenExpanded) {
        this.loadChildren();
      }
    },
    reloadCurrentLevel() {
      if (this.reloadCurrentLevel && this.children.find((item) => item.id == this.currentItemId)) {
        this.loadChildren();
      }
    },
    children() {
      if (this.children && this.children.length > 0) {
        this.childrenExpanded = true;
      } else if (this.childrenLoaded) {
        this.item.has_children = false;
      }
    },
    archived() {
      if (this.childrenExpanded) {
        this.loadChildren();
      }
    }
  },
  methods: {
    toggleChildren() {
      this.childrenExpanded = !this.childrenExpanded;
      if (this.childrenExpanded) this.loadChildren();
    },
    loadChildren() {
      $.get(this.item.children_url, { archived: this.archived }, (data) => {
        this.children = data.items;
        this.childrenLoaded = true;
      });
    },
    treeExpand() {
      this.childrenExpanded = true;
      this.$emit('item:expand');
    },
    selectItem() {
      if (this.activeItem && !this.childrenExpanded) {
        this.$emit('item:expand');
        if (this.hasChildren) {
          this.childrenExpanded = true;
          this.loadChildren();
        }
      }
    }
  }
};
</script>
