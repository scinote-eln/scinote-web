<template>
  <div class="relative" v-click-outside="closeMenu" >
    <div ref="field" class="cursor-pointer" @click.stop="isOpen = (!isOpen || fieldOnlyOpen)">
      <slot name="field"></slot>
    </div>
    <template v-if="isOpen">
      <teleport to="body">
        <div ref="flyout"
            class="sn-dropdown fixed z-[3000] bg-sn-white inline-block
                  rounded p-2.5 sn-shadow-menu-sm"
            :class="{
                'right-0': position === 'right',
                'left-0': position === 'left',
            }"
        >
          <slot name="flyout"></slot>
        </div>
      </teleport>
    </template>
  </div>
</template>

<script>

import { vOnClickOutside } from '@vueuse/components';
import FixedFlyoutMixin from './mixins/fixed_flyout.js';

export default {
  name: 'DropdownMenu',
  props: {
    listItems: { type: Array, default: () => [] },
    position: { type: String, default: 'left' },
    btnClasses: { type: String, default: 'btn btn-light' },
    btnText: { type: String, required: false },
    btnIcon: { type: String, required: false },
    caret: { type: Boolean, default: false },
    alwaysShow: { type: Boolean, default: false },
    closeDropdown: { type: Boolean, default: false },
    fieldOnlyOpen: { type: Boolean, default: false },
    fixedWidth: { type: Boolean, default: false }
  },
  data() {
    return {
      isOpen: false
    };
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  mixins: [FixedFlyoutMixin],
  watch: {
    isOpen() {
      if (this.isOpen) {
        this.$emit('open');
        this.$nextTick(() => {
          this.setPosition();
        });
      } else {
        this.$emit('close');
      }
    }
  },
  methods: {
    closeMenu(e) {
      if (e && e.target.closest('.sn-dropdown, .sn-select-dropdown, .sn-menu-dropdown, .dp__instance_calendar')) return;
      this.isOpen = false;
    }
  }
};
</script>
