<template>
  <div class="filter-container dropdown">
    <button class="btn btn-light icon-btn btn-black filter-button" :title="i18n.t('filters_modal.title')" data-toggle="dropdown"><i class="sn-icon sn-icon-filter"></i></button>
    <div class="dropdown-menu dropdown-menu-right filter-dropdown">
      <div class="header">
        <div class="title">{{ i18n.t('filters_modal.title') }}</div>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
      </div>
      <div class="body p-3">
        <div v-for="filter in filters" :key="filter.key">
          <template v-if="filter.type === 'text'">
            <label>{{ filter.label }}</label>
            <div class="sci-input-container">
              <input class="sci-input-field"
                     type="text"
                     :id="filter.key"
                     :placeholder="filter.placeholder"
                     :value="filterValues[filter.key] && filterValues[filter.key].value"
                     @input="updateFilter(filter.key, $event.currentTarget.value)">
            </div>
          </template>
        </div>
      </div>
      <div class="footer">
        <div class="buttons">
          <div @click="filterValues = {}" class="btn btn-secondary">
            {{ i18n.t('filters_modal.clear_btn') }}
          </div>
          <div @click="$emit('applyFilters', filterValues)" class="btn btn-primary">
            {{ i18n.t('filters_modal.show_btn.one') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
  import Select from './select.vue'
  import DropdownSelector from './dropdown_selector.vue'
  import DateTimePicker from './date_time_picker.vue'

  export default {
    name: 'FilterDropdown',
    props: {
      filters: { type: Array, required: true }
    },
    components: { Select, DropdownSelector, DateTimePicker },
    data() {
      return {
        filterValues: {}
      }
    },
    computed: {
    },
    mounted() {
    },
    methods: {
      updateFilter(key, value) {
        this.filterValues[key] = value;
      }
    }
  }
</script>
