<template>
  <div class="px-4 py-2 bg-sn-super-light-blue flex gap-4 mt-10 mb-4 rounded">
    <span class="font-bold shrink-0 leading-10">
      {{ i18n.t('protocols.steps.insert.button') }}:
    </span>
    <div class="flex items-center gap-2 flex-wrap">
      <template v-for="item in insertMenu">
        <button v-if="!item.submenu" @click="$emit(item.emit)" class="btn btn-light">
          <i :class="item.icon"></i>
          <span class="tw-hidden xl:inline">{{ item.text }}</span>
        </button>
        <MenuDropdown
          :listItems="item.submenu"
          :btnText="item.text"
          :disableOverflow="true"
          :btnClasses="'btn btn-light'"
          :smallScreenCollapse="true"
          :position="'right'"
          :caret="true"
          :btnIcon="item.icon"
          @dtEvent="handleEvents"
        ></MenuDropdown>
      </template>
    </div>
  </div>
</template>
<script>
import MenuDropdown from '../menu_dropdown.vue';

export default {
  components: {
    MenuDropdown
  },
  name: 'stepToolbar',
  props: {
    insertMenu: Array
  },
  methods: {
    handleEvents(event, option) {
      this.$emit(event, option.params);
    }
  }

};
</script>
