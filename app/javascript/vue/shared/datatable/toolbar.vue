<template>
  <div class="flex py-4 items-center">
    <div class="flex items-center gap-4">
      <a v-for="action in toolbarActions.left" :key="action.label"
          :class="action.buttonStyle"
          :href="action.path"
          @click="doAction(action, $event)">
        <i :class="action.icon"></i>
        {{ action.label }}
      </a>
    </div>
    <div class="ml-auto flex items-center gap-4">
      <a v-for="action in toolbarActions.right" :key="action.label"
          :class="action.buttonStyle"
          :href="action.path"
          @click="doAction(action, $event)">
        <i :class="action.icon"></i>
        {{ action.label }}
      </a>
      <div class="sci-input-container-v2" :class="{'w-48': showSearch, 'w-11': !showSearch}">
        <input
          ref="searchInput"
          class="sci-input-field !pr-8"
          type="text"
          @focus="openSearch"
          @blur="hideSearch"
          :value="searchValue"
          :placeholder="'Search...'"
          @change="$emit('search:change', $event.target.value)"
        />
        <i class="sn-icon sn-icon-search !m-2.5 !ml-auto right-0"></i>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Toolbar',
  props: {
    toolbarActions: {
      type: Object,
      required: true
    },
    searchValue: {
      type: String,
    }
  },
  data() {
    return {
      showSearch: false
    }
  },
  watch: {
    searchValue() {
      if (this.searchValue.length > 0) {
        this.openSearch();
      }
    }
  },
  methods: {
    openSearch() {
      this.showSearch = true;
    },
    hideSearch() {
      if (this.searchValue.length === 0) {
        this.showSearch = false;
      }
    },
    doAction(action, event) {
      switch(action.type) {
        case 'emit':
          event.preventDefault();
          this.$emit('toolbar:action', action);
          break;
        case 'link':
          break;
      }
    }
  }
}
</script>
