<template>
  <div class="filter-container">
    <div class='filter-title'>{{ filter.column.name }}</div>
    <div class="filter-element">
      <div class="filter-body">
        <component
          :is="filter.column.data_type"
          :filter="filter"
          :my_modules='my_modules'
          @filter:update="updateFilter" />
      </div>
      <div class="filter-remove">
        <button class="btn btn-light icon-btn" @click="$emit('filter:delete')">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
</div>
</template>

<script>
  // filter types
  import RepositoryAssetValue from 'vue/repository_filter/filters/repositoryAssetValue.vue'
  import RepositoryTextValue from 'vue/repository_filter/filters/repositoryTextValue.vue'
  import RepositoryNumberValue from 'vue/repository_filter/filters/repositoryNumberValue.vue'
  import RepositoryMyModuleValue from 'vue/repository_filter/filters/repositoryMyModuleValue.vue'
  import RepositoryDateValue from 'vue/repository_filter/filters/repositoryDateValue.vue'
  import RepositoryDateRangeValue from 'vue/repository_filter/filters/repositoryDateRangeValue.vue'
  import RepositoryDateTimeValue from 'vue/repository_filter/filters/repositoryDateTimeValue.vue'
  import RepositoryDateTimeRangeValue from 'vue/repository_filter/filters/repositoryDateTimeRangeValue.vue'
  import RepositoryTimeValue from 'vue/repository_filter/filters/repositoryTimeValue.vue'
  import RepositoryTimeRangeValue from 'vue/repository_filter/filters/repositoryTimeRangeValue.vue'
  import RepositoryListValue from 'vue/repository_filter/filters/repositoryListValue.vue'
  import RepositoryStatusValue from 'vue/repository_filter/filters/repositoryStatusValue.vue'
  import RepositoryChecklistValue from 'vue/repository_filter/filters/repositoryChecklistValue.vue'
  import RepositoryUserValue from 'vue/repository_filter/filters/repositoryUserValue.vue'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'


  export default {
    name: "FilterElement",
    props: {
      filter: Object,
      my_modules: Array
    },
    components: {
      DropdownSelector,
      RepositoryAssetValue,
      RepositoryTextValue,
      RepositoryNumberValue,
      RepositoryMyModuleValue,
      RepositoryDateValue,
      RepositoryDateRangeValue,
      RepositoryTimeValue,
      RepositoryTimeRangeValue,
      RepositoryDateTimeValue,
      RepositoryDateTimeRangeValue,
      RepositoryListValue,
      RepositoryStatusValue,
      RepositoryChecklistValue,
      RepositoryListValue,
      RepositoryUserValue
    },
    methods: {
      updateFilter(value) {
        this.$emit('filter:update', value)
      }
    }
  }
</script>
