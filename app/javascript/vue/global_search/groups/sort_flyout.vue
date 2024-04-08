<template>
  <MenuDropdown
      class="ml-auto"
      :listItems="sortOptions"
      btnClasses="btn btn-light icon-btn btn-black"
      position="right"
      @dtEvent="changeSort"
      btnIcon="sn-icon sn-icon-sort-down"
    ></MenuDropdown>
</template>

<script>
import MenuDropdown from '../../shared/menu_dropdown.vue';

export default {
  name: 'SortFlyout',
  props: {
    sort: {
      type: String,
      default: 'created_desc'
    }
  },
  components: {
    MenuDropdown
  },
  computed: {
    sortOptions() {
      return ['created_desc', 'created_asc', 'atoz', 'ztoa'].map((sort) => (
        {
          emit: sort,
          text: this.i18n.t(`search.index.${sort}`),
          active: this.sort === sort
        }
      ));
    }
  },
  methods: {
    changeSort(value) {
      this.$emit('changeSort', value);
    }
  }
};
</script>
