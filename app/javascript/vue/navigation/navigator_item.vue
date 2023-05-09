<template>
  <div class="text-sn-blue pl-7 w-64 flex justify-center flex-col" :navigator-item-id="item.id">
    <div class="p-2 flex items-center whitespace-nowrap" :title="this.itemToolTip" :class="{ 'bg-sn-light-grey': activeItem }">
      <div class="w-5 mr-2 flex justify-start shrink-0">
        <i v-if="hasChildren"
          class="fas cursor-pointer"
          :class="{'fa-chevron-right': !childrenExpanded, 'fa-chevron-down': childrenExpanded }"
          @click="toggleChildren"></i>
      </div>
      <a :href="item.url"
          class="text-ellipsis overflow-hidden hover:no-underline"
          :class="{
            'pointer-events-none': (!item.archived && archived),
            'text-sn-grey': (!item.archived && archived)
          }">
        <i v-if="itemIcon" class="mr-2" :class="itemIcon"></i>
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
        if (a.name < b.name) {
          return -1;
        }
        if (a.name > b.name) {
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
          return 'fas fa-folder';
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
