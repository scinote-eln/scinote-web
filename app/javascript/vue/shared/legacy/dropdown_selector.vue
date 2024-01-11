<template>
  <div class="dropdown-selector">
    <select :id="this.selectorId"
            :data-select-by-group="groupSelector"
            :data-combine-tags="dataCombineTags"
            :data-select-multiple-all-selected="dataSelectMultipleAllSelected"
            :data-select-multiple-name="dataSelectMultipleName"
            :data-placeholder="placeholder"
            :data-view-mode="viewMode"
    >
      <template v-if="groupSelector">
        <optgroup v-for="group in this.options" :label="group.label" :key="group.label">
          <option v-for="option in group.options"
            :key="option.value"
            :value="option.value"
            :selected="option.value == selectedValue || (Array.isArray(selectedValue) && selectedValue.some(e => e == option.value))"
            :data-selected="option.value == selectedValue || (Array.isArray(selectedValue) && selectedValue.some(e => e == option.value))"
            :data-params="JSON.stringify(option.params)"
            :data-group="group.label">
            {{ option.label }}
          </option>
        </optgroup>
      </template>
      <template v-else>
        <option
          v-for="option in this.options"
          :key="option.value"
          :value="option.value"
          :selected="option.value == selectedValue || (Array.isArray(selectedValue) && selectedValue.some(e => e == option.value))"
          :data-selected="option.value == selectedValue || (Array.isArray(selectedValue) && selectedValue.some(e => e == option.value))"
          :data-params="JSON.stringify(option.params)">
          {{ option.label }}
        </option>
      </template>
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
      type: [String, Number, Boolean, Array],
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
    labelHTML: {
      type: Boolean,
      default: false
    },
    tagLabel: {
      type: Function
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
    onOpen: {
      type: Function
    },
    inputTagMode: {
      type: Boolean,
      default: false
    },
    viewMode: {
      type: Boolean,
      default: false
    },
    onChange: Function

  },
  mounted() {
    dropdownSelector.init(`#${this.selectorId}`, {
      inputTagMode: this.inputTagMode,
      optionClass: this.optionClass,
      optionLabel: this.optionLabel,
      noEmptyOption: this.noEmptyOption,
      singleSelect: this.singleSelect,
      closeOnSelect: this.closeOnSelect,
      selectAppearance: this.selectAppearance,
      disableSearch: this.disableSearch,
      tagLabel: this.tagLabel,
      labelHTML: this.labelHTML,
      onOpen: this.onOpen,
      onChange: () => {
        if (this.onChange) this.onChange();
        this.selectChanged(dropdownSelector.getValues(`#${this.selectorId}`));
      }
    });
  },
  methods: {
    selectChanged(value) {
      this.$emit(
        'dropdown:changed',
        value
      );
    },
    selectValues(value) {
      dropdownSelector.selectValues(`#${this.selectorId}`, value);
    }
  }
};
</script>
