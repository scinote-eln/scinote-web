<template>
  <div class="relative" v-click-outside="closeMenu" >
    <div ref="field" :class="{ 'cursor-pointer': canOpen }" @click.stop="toggleMenu">
      <slot name="field"></slot>
    </div>
    <template v-if="isOpen">
      <teleport to="body">
        <div @click="closeOnClick && closeMenu()" ref="flyout"
            :id="randomId"
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
    closeOnClick: { type: Boolean, default: false },
    fieldOnlyOpen: { type: Boolean, default: false },
    canOpen: { type: Boolean, default: true },
    fixedWidth: { type: Boolean, default: false }
  },
  data() {
    return {
      isOpen: false,
      randomId: `dropdown-${Math.random().toString(36).substring(2, 15)}`,
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
    toggleMenu() {
      if (this.canOpen && (!this.isOpen || this.fieldOnlyOpen)) {
        this.isOpen = true;
      } else if (this.isOpen && !this.fieldOnlyOpen) {
        this.isOpen = false;
      }
    },
    closeMenu(e) {
      if (e && e.target.closest(`.sn-dropdown#${this.randomId}, .sn-select-dropdown, .sn-menu-dropdown, .dp__instance_calendar`)) return;
      this.isOpen = false;
    }
  }
};
</script>
