<template>
  <div class="relative" v-if="listItems.length > 0" >
    <button ref="openBtn" :class="btnClasses" @click="showMenu = !showMenu">
      <i v-if="btnIcon" :class="btnIcon"></i>
      {{ btnText }}
      <i v-if="caret && showMenu" class="fas fa-caret-up"></i>
      <i v-else-if="caret" class="fas fa-caret-down"></i>
    </button>
    <div ref="flyout"
         class="absolute z-50 bg-sn-white rounded p-2.5 sn-shadow-menu-sm"
         :class="{'right-0': position === 'right', 'left-0': position === 'left'}"
         v-if="showMenu"
         v-click-outside="{handler: 'closeMenu', exclude: ['openBtn', 'flyout']}">
      <a v-for="(item, i) in listItems"
         :key="i"
         :href="item.url"
         class="block whitespace-nowrap px-3 py-2.5 hover:no-underline cursor-pointer hover:bg-sn-super-light-blue"
         @click="handleClick($event, item)"
      >
        {{ item.text }}
      </a>
    </div>
  </div>
</template>

<script>

export default {
  name: 'DropdownMenu',
  props: {
    listItems: { type: Array, required: true },
    position: { type: String, default: 'left' },
    btnClasses: { type: String, default: 'btn btn-light' },
    btnText: { type: String, required: false },
    btnIcon: { type: String, required: false },
    caret: { type: Boolean, default: false },
  },
  data() {
    return {
      showMenu: false,
    }
  },
  methods: {
    closeMenu() {
      this.showMenu = false;
    },
    handleClick(event, item) {
      if (!item.url) {
        event.preventDefault();
      }

      if (item.emit) {
        this.$emit(item.emit)
      }

      this.showMenu = false;
    }
  }
}
</script>
