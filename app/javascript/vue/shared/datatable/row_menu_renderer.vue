<template>
  <div>
    <MenuDropdown
      :listItems="this.formattedList"
      btnClasses="bg-transparent w-6 h-6 border-0 p-0 flex"
      :position="'right'"
      :alwaysShow="true"
      :btnIcon="'sn-icon sn-icon-more-hori'"
      @open="loadActions"
      @dtEvent="handleEvents"
    ></MenuDropdown>
  </div>
</template>

<script>
import MenuDropdown from '../menu_dropdown.vue';
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'RowMenuRenderer',
  props: {
    params: {
      required: true,
    },
  },
  data() {
    return {
      actionsMenu: [],
    };
  },
  components: {
    MenuDropdown,
  },
  computed: {
    formattedList() {
      return this.actionsMenu.map((item) => {
        const newItem = { text: item.label };
        if (item.type === 'emit') {
          newItem.emit = item.name;
        }
        if (item.type === 'link') {
          newItem.url = item.path;
        }

        newItem.params = item;

        return newItem;
      });
    },
  },
  methods: {
    loadActions() {
      if (this.actionsMenu.length > 0) return;
      axios.get(this.params.data.urls.actions)
        .then((response) => {
          this.actionsMenu = response.data.actions;
        });
    },
    handleEvents(event, option) {
      const dt = this.params.dtComponent;
      dt.$emit(event, option.params, [this.params.data]);
    },
  },
};
</script>
