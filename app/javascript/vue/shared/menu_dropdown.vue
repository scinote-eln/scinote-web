<template>
  <div class="relative" v-if="listItems.length > 0" >
    <button ref="openBtn" :class="btnClasses" @click="showMenu = !showMenu">
      <i v-if="btnIcon" :class="btnIcon"></i>
      {{ btnText }}
      <i v-if="caret && showMenu" class="sn-icon sn-icon-up"></i>
      <i v-else-if="caret" class="sn-icon sn-icon-down"></i>
    </button>
    <div ref="flyout"
         class="absolute z-[150] bg-sn-white rounded p-2.5 sn-shadow-menu-sm min-w-full"
         :class="{'right-0': position === 'right', 'left-0': position === 'left'}"
         v-if="showMenu"
         v-click-outside="{handler: 'closeMenu', exclude: ['openBtn', 'flyout']}">
      <span v-for="(item, i) in listItems" :key="i">
        <a :href="item.url" v-if="!item.submenu"
          :class="{'border-0 border-t border-solid border-sn-light-grey': item.dividerBefore}"
          :traget="item.url_target || '_self'"
          class="block whitespace-nowrap px-3 py-2.5 hover:no-underline cursor-pointer hover:bg-sn-super-light-blue"
          @click="handleClick($event, item)"
        >
          {{ item.text }}
        </a>
        <span v-else
              @click="showSubmenu = i"
              :class="{'!bg-sn-super-light-grey': showSubmenu == i}"
              class="flex group items-center relative text-sn-blue whitespace-nowrap px-3 py-2.5 hover:no-underline cursor-pointer hover:bg-sn-super-light-blue"
        >
          {{ item.text }}
          <i class="sn-icon sn-icon-right ml-auto"></i>
          <div v-if="showSubmenu == i"
               class="absolute top-0 bg-sn-white rounded p-2.5 sn-shadow-menu-sm"
               :class="{
                 'left-0 ml-[calc(100%_+_0.625rem)]': item.position === 'right',
                 'right-0 mr-[calc(100%_+_0.625rem)]': item.position === 'left'
               }"
          >
            <a v-for="(sub_item, si) in item.submenu" :key="si"
              :href="sub_item.url"
              :traget="sub_item.url_target || '_self'"
              class="block whitespace-nowrap px-3 py-2.5 hover:no-underline cursor-pointer hover:bg-sn-super-light-blue"
              @click="handleClick($event, sub_item)"
            >
              {{ sub_item.text }}
            </a>
          </div>
        </span>
      </span>
    </div>
  </div>
</template>

<script>

export default {
  name: 'DropdownMenu',
  props: {
    listItems: { type: Array, default: () => [] },
    position: { type: String, default: 'left' },
    btnClasses: { type: String, default: 'btn btn-light' },
    btnText: { type: String, required: false },
    btnIcon: { type: String, required: false },
    caret: { type: Boolean, default: false },
  },
  data() {
    return {
      showMenu: false,
      showSubmenu: null,
    }
  },
  methods: {
    closeMenu() {
      this.showMenu = false;
      this.showSubmenu = null;
    },
    handleClick(event, item) {
      if (!item.url) {
        event.preventDefault();
      }

      if (item.emit) {
        this.$emit(item.emit, item.params)
      }

      this.closeMenu();
    }
  }
}
</script>
