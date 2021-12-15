<template>
  <div class="dropdown-selector">
    <select :id="this.selectorId"
            :data-select-by-group="groupSelector"
            :data-combine-tags="dataCombineTags"
            :data-select-multiple-all-selected="dataSelectMultipleAllSelected"
            :data-select-multiple-name="dataSelectMultipleName"
            :data-placeholder="placeholder"
    >
      <optgroup v-if="groupSelector" v-for="group in this.options" :label="group.label">
        <option v-for="option in group.options" :key="option.label" :value="option.value" :data-params="JSON.stringify(option.params)">
          {{ option.label }}
        </option>
      </optgroup>
      <option v-if="!groupSelector"
        v-for="option in this.options"
        :key="option.label"
        :value="option.value"
        :selected="option.value == selectedValue"
        :data-selected="option.value == selectedValue"
        :data-params="JSON.stringify(option.params)">
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
      groupSelector: {
        type: Boolean,
        default: false
      },
      noEmptyOption: {
        type: Boolean,
        default: true
      },
      placeholder: {
        type: String,
        default: ''
      },
      selectedValue: {
        type: [String, Number, Boolean],
        default: null
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
      optionClass: {
        type: String,
        default: ''
      },
      dataCombineTags: {
        type: Boolean,
        default: false
      },
      dataSelectMultipleAllSelected: {
        type: String,
        default: ''
      },
      dataSelectMultipleName: {
        type: String,
        default: ''
      },
      optionLabel: {
        type: Function
      },
      onChange: Function

    },
    mounted: function() {
      dropdownSelector.init(`#${this.selectorId}`, {
        optionClass: this.optionClass,
        optionLabel: this.optionLabel,
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
