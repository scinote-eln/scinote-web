<template>
  <div class="dropdown-selector">
    <select :id="this.selectorId">
      <option
        v-for="option in this.options"
        :key="option.label" :value="option.value">
          {{ option.label }}
      </option>
    </select>
  </div>
</template>

<script>
  export default {
    name: 'DropdownSelector',
    props: {
      options: Array,
      selectorId: String,
      noEmptyOption: {
        type: Boolean,
        default: true
      },
      singleSelect: {
        type: Boolean,
        default: true
      },
      closeOnSelect: {
        type: Boolean,
        default: true
      },
      selectAppearance: {
        type: String,
        default: 'simple'
      },
      disableSearch: {
        type: Boolean,
        default: false
      },
      onChange: Function

    },
    mounted: function() {
      dropdownSelector.init(`#${this.selectorId}`, {
        noEmptyOption: this.noEmptyOption,
        singleSelect: this.singleSelect,
        closeOnSelect: this.closeOnSelect,
        selectAppearance: this.selectAppearance,
        disableSearch: this.disableSearch,
        onChange: () => {
          if (this.onChange) this.onChange();
          this.selectChanged(dropdownSelector.getValues(`#${this.selectorId}`))
        }
      });
    },
    methods: {
      selectChanged(value) {
        this.$emit(
          'dropdown:changed',
          value
        );
      }
    }
  }
</script>
