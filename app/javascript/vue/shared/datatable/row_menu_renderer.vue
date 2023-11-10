<template>
  <div class="flex items-center">
    <MenuDropdown
      :listItems="this.formattedList"
      :btnClasses="'btn btn-light icon-btn'"
      :position="'right'"
      :alwaysShow="true"
      :btnIcon="'sn-icon sn-icon-more-hori'"
      @open="loadActions"
    ></MenuDropdown>
  </div>
</template>

<script>
import MenuDropdown from '../menu_dropdown.vue'
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'RowMenuRenderer',
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      actionsMenu: []
    }
  },
  components: {
    MenuDropdown
  },
  computed: {
    formattedList() {
      return this.actionsMenu.map((item) => {
        let newItem = { text: item.label }
        if (item.type == 'emit') {
          newItem.emit = item.name
        }
        if (item.type == 'link') {
          newItem.url = item.path
        }

        return newItem
      })
    }
  },
  methods: {
    loadActions() {
      if (this.actionsMenu.length > 0) return

      axios.get(this.params.data.urls.actions)
        .then((response) => {
          this.actionsMenu = response.data.actions
        })
        .catch((error) => {
          console.log(error)
        })
    }
  }
}
</script>
