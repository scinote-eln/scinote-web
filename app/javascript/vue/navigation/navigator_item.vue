<template>
  <div class="text-sn-blue min-w-[170px] w-full flex justify-center flex-col"
       :class="{ 'pl-6': !firstLevel }"
       :navigator-item-id="item.id"
  >
    <div class="py-1.5 px-1 menu-item flex items-center whitespace-nowrap" :title="this.itemToolTip" :class="{ 'bg-sn-light-grey active': activeItem }">
      <div class="w-6 h-6 flex justify-start shrink-0 mr-1.5">
        <i v-if="hasChildren"
          class="sn-icon cursor-pointer"
          :class="{'sn-icon-right': !childrenExpanded, 'sn-icon-down': childrenExpanded }"
          @click="toggleChildren"></i>
      </div>
      <i v-if="itemIcon" class="mr-1" :class="itemIcon"></i>
      <a :href="item.url"
          class="text-ellipsis overflow-hidden hover:no-underline pr-3"
          :class="{
            'text-sn-science-blue-hover': (!item.archived && archived)
          }">
        <template v-if="item.archived">(A)</template>
        {{ item.name }}
      </a>
    </div>
    <div class="basis-full" :class="{'hidden': !childrenExpanded}">
      <NavigatorItem v-for="item in sortedMenuItems"
                     @item:expand="treeExpand"
                     :key="item.id"
                     :currentItemId="currentItemId"
                     :reloadCurrentLevel="reloadCurrentLevel"
                     :reloadChildrenLevel="reloadChildrenLevel"
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
    reloadCurrentLevel: Boolean,
    reloadChildrenLevel: Boolean
  },
  data: function() {
    return {
      childrenExpanded: false,
      childrenLoaded: false,
      children: []
    };
  },
  computed: {
    hasChildren: function() {
      return this.item.has_children || this.children.length > 0;
    },
    sortedMenuItems: function() {
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
    activeItem: function() {
      return this.item.id == this.currentItemId;
    },
    itemIcon: function() {
      switch(this.item.type) {
        case 'folder':
          return 'sn-icon mini sn-icon-mini-folder-left';
        default:
          return null;
      }
    },
    itemToolTip: function() {
      if (this.item.type == 'folder')
        return this.item.name;
      return this.i18n.t('sidebar.elements_tooltip', { type: this.i18n.t(`activerecord.models.${this.item.type}`), name: this.item.name});
    }
  },
  created: function() {
    if (this.item.children) this.children = this.item.children;
  },
  mounted: function() {
    this.selectItem();
  },
  watch: {
    currentItemId: function() {
      this.selectItem();
    },
    reloadChildrenLevel: function() {
      if (this.reloadChildrenLevel && this.item.id == this.currentItemId) {
        this.loadChildren();
      }
    },
    reloadCurrentLevel: function() {
      if (this.reloadCurrentLevel && this.children.find((item) => item.id == this.currentItemId)) {
        this.loadChildren();
      }
    },
    children: function() {
      if (this.children.length > 0) {
        this.childrenExpanded = true;
      } else if (this.childrenLoaded) {
        this.item.has_children = false;
      }
    }
  },
  methods: {
    toggleChildren: function() {
      this.childrenExpanded = !this.childrenExpanded;
      if (this.childrenExpanded) this.loadChildren();
    },
    loadChildren: function() {
      $.get(this.item.children_url, {archived: this.archived}, (data) => {
        this.children = data.items;
        this.childrenLoaded = true;
      });
    },
    treeExpand: function() {
      this.childrenExpanded = true;
      this.$emit('item:expand');
    },
    selectItem: function() {
      if (this.activeItem && !this.childrenExpanded) {
        this.$emit('item:expand');
        if (this.hasChildren) {
          this.childrenExpanded = true;
          this.loadChildren();
        }
      }
    }
  },
}
</script>
