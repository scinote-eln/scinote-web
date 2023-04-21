<template>
  <div class="sn-color-primary pl-7 w-64 flex justify-center flex-col" :navigator-item-id="item.id">
    <div class="p-2 flex items-center whitespace-nowrap" :class="{ 'sn-background-background-violet': activeItem }">
      <div class="w-5 mr-2 flex justify-start shrink-0">
        <i v-if="hasChildren"
          class="fas cursor-pointer"
          :class="{'fa-chevron-right': !childrenExpanded, 'fa-chevron-down': childrenExpanded }"
          @click="toggleChildren"></i>
      </div>
      <i v-if="itemIcon" class="mr-2" :class="itemIcon"></i>
      <a :href="item.url" class="text-ellipsis overflow-hidden">
        {{ item.name }}
      </a>
    </div>
    <div class="basis-full" :class="{'hidden': !childrenExpanded}">
      <NavigatorItem v-for="item in sortedMenuItems" @item:expand="treeExpand" :key="item.id" :currentItemId="currentItemId" :item="item" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'NavigatorItem',
  props: {
    item: Object,
    currentItemId: String
  },
  data: function() {
    return {
      childrenExpanded: false,
      children: []
    };
  },
  computed: {
    hasChildren: function() {
      return this.item.has_children;
    },
    sortedMenuItems: function() {
      return this.children.sort((a, b) => a.name - b.name);
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
    }
  },
  methods: {
    toggleChildren: function() {
      this.childrenExpanded = !this.childrenExpanded;
      if (this.childrenExpanded) this.loadChildren();
    },
    loadChildren: function() {
      $.get(this.item.children_url, {archived: false}, (data) => {
        this.children = data.items;
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
