<template>
  <div v-click-outside="close" class="w-full">
    <div
      ref="field"
      class="px-3 border border-solid border-sn-light-grey rounded flex items-center cursor-pointer"
      @click="open"
      :class="[sizeClass, {
        'border-sn-blue': isOpen,
        'bg-sn-sleepy-grey': disabled
      }]"
    >
      <template v-if="!isOpen || !searchable">
        <div class="truncate" v-if="labelRenderer && label" v-html="label"></div>
        <div class="truncate" v-else-if="label">{{ label }}</div>
        <div class="text-sn-grey truncate" v-else>{{ placeholder }}</div>
      </template>
      <input type="text"
             ref="search"
             v-else
             v-model="query"
             :placeholder="label || placeholder"
             class="w-full border-0 outline-none pl-0 placeholder:text-sn-grey" />
      <i v-if="canClear" @click="clear" class="sn-icon ml-auto sn-icon-close"></i>
      <i v-else class="sn-icon ml-auto" :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen, 'text-sn-grey': disabled}"></i>
    </div>
    <div v-if="isOpen" ref="flyout" class="bg-white sn-shadow-menu-sm rounded w-full fixed z-50">
      <div v-if="multiple && withCheckboxes" class="p-2.5 pb-0">
        <div @click="selectAll" :class="sizeClass" class="border-transparent border-solid border-b-sn-light-grey py-1.5 px-3  cursor-pointer flex items-center gap-2 shrink-0">
          <div class="sn-checkbox-icon"
              :class="selectAllState"
          ></div>
          {{ i18n.t('general.select_all') }}
        </div>
      </div>
      <perfect-scrollbar class="p-2.5 flex flex-col max-h-80 relative" :class="{ 'pt-0': withCheckboxes }">
        <template v-for="option in filteredOptions" :key="option[0]">
          <div
            @click="setValue(option[0])"
            class="py-1.5 px-3 rounded cursor-pointer flex items-center gap-2 shrink-0"
            :class="[sizeClass, {'!bg-sn-super-light-blue': valueSelected(option[0])}]"
          >
            <div v-if="withCheckboxes"
                 class="sn-checkbox-icon"
                 :class="{
                  'checked': valueSelected(option[0]),
                  'unchecked': !valueSelected(option[0]),
                 }"
            ></div>
            <div v-if="optionRenderer" v-html="optionRenderer(option)"></div>
            <div v-else >{{ option[1] }}</div>
          </div>
        </template>
        <div v-if="filteredOptions.length === 0" class="text-sn-grey text-center py-2.5">
          {{ noOptionsPlaceholder }}
        </div>
      </perfect-scrollbar>
    </div>
  </div>

</template>

<script>
import { vOnClickOutside } from '@vueuse/components'

export default {
  name: 'SelectDropdown',
  props: {
    value: { type: [String, Number, Array] },
    options: { type: Array, default: () => [] },
    optionsUrl: { type: String },
    placeholder: { type: String },
    noOptionsPlaceholder: { type: String },
    fewOptionsPlaceholder: { type: String },
    allOptionsPlaceholder: { type: String },
    optionRenderer: { type: Function },
    labelRenderer: { type: Function },
    disabled: { type: Boolean, default: false },
    size: { type: String, default: 'md' },
    multiple: { type: Boolean, default: false },
    withCheckboxes: { type: Boolean, default: false },
    searchable: { type: Boolean, default: false },
    clearable: { type: Boolean, default: false },
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  data() {
    return {
      newValue: null,
      isOpen: false,
      fetchedOptions: [],
      selectAllState: 'unchecked',
      query: '',
    }
  },
  computed: {
    sizeClass() {
      switch (this.size) {
        case 'xs':
          return 'min-h-[36px]'
        case 'sm':
          return 'min-h-[40px]'
        case 'md':
          return 'min-h-[44px]'
      }
    },
    canClear() {
      return this.clearable && this.label && this.isOpen
    },
    rawOptions() {
      if (this.optionsUrl) {
        return this.fetchedOptions
      } else {
        return this.options
      }
    },
    filteredOptions() {
      if (this.query.length > 0 && !this.optionsUrl ) {
        return this.rawOptions.filter(option => {
          return option[1].toLowerCase().includes(this.query.toLowerCase())
        })
      } else {
        return this.rawOptions
      }
    },
    label() {
      if (this.multiple) {
        return this.multipleLabel
      } else {
        return this.singleLabel
      }
    },

    singleLabel() {
      const option = this.rawOptions.find(option => option[0] === this.newValue)
      return this.renderLabel(option)
    },
    multipleLabel() {
      if (!this.newValue) return false;

      this.selectAllState = 'indeterminate'

      if (this.newValue.length === 0) {
        this.selectAllState = 'unchecked';
        return false;
      } else if (this.newValue.length === 1) {
        return this.renderLabel(this.rawOptions.find(option => option[0] === this.newValue[0]))
      } else if (this.newValue.length === this.rawOptions.length) {
        this.selectAllState = 'checked';
        return this.allOptionsPlaceholder
      } else {
        return `${this.newValue.length} ${this.fewOptionsPlaceholder}`
      }
    },
  },
  mounted() {
    document.addEventListener('scroll', this.setPosition);
    this.newValue = this.value;
    if (!this.newValue && this.multiple) {
      this.newValue = []
    }
    this.fetchOptions();
  },
  beforeUnmount() {
    document.removeEventListener('scroll', this.setPosition);
  },
  watch: {
    isOpen() {
      if (this.isOpen) {
        this.$nextTick(() => {
          this.setPosition();
          this.$refs.search?.focus();
        })
      }
    },
    query() {
      if (this.optionsUrl) this.fetchOptions();
    },
  },
  methods: {
    renderLabel(option) {
      if (!option) return false;

      if (this.labelRenderer) {
        return this.labelRenderer(option)
      } else {
        return option[1]
      }
    },
    valueSelected(value) {
      if (!this.newValue) return false;
      if (this.multiple) {
        return this.newValue.includes(value);
      } else {
        return this.newValue == value;
      }
    },
    open() {
      if (!this.disabled) this.isOpen = true
    },
    clear() {
      this.newValue = null
      this.query = '';
      this.$emit('change', this.newValue)
    },
    close() {
      this.isOpen = false
      if (this.newValue != this.value) {
        this.$emit('change', this.newValue)
      }
      this.query = '';
    },
    setValue(value) {
      if(this.multiple) {
        if (this.newValue.includes(value)) {
          this.newValue = this.newValue.filter(v => v != value)
        } else {
          this.newValue.push(value)
        }
      } else {
        this.newValue = value
        this.close()
      }
    },
    selectAll() {
      if (this.selectAllState === 'checked') {
        this.newValue = []
      } else {
        this.newValue = this.rawOptions.map(option => option[0])
      }
      this.$emit('change', this.newValue)
    },
    setPosition() {
        const field= this.$refs.field;
        const flyout = this.$refs.flyout;
        const rect = field.getBoundingClientRect();
        const screenHeight = window.innerHeight;

        if (!this.isOpen) return;

        let width = rect.width;
        let height = rect.height;
        let top = rect.top + rect.height;
        let bottom = screenHeight - rect.bottom + rect.height;
        let left = rect.left;

        flyout.style.width = `${width}px`;
        flyout.style.top = `${top}px`;
        flyout.style.left = `${left}px`;
        if (bottom < top) {
          flyout.style.marginTop = `${(height + flyout.offsetHeight)* -1}px`;
          flyout.style.boxShadow = '0px -16px 32px 0px rgba(16, 24, 40, 0.07)';
        } else {
          flyout.style.marginTop = '';
          flyout.style.boxShadow = '';
        }
    },
    fetchOptions() {
      if (this.optionsUrl) {
        fetch(`${this.optionsUrl}?query=${this.query || ''}`)
          .then(response => response.json())
          .then(data => {
            this.fetchedOptions = data.data;
            this.$nextTick(() => {
              this.setPosition();
            })
          })
      }
    }
  },
}
</script>
