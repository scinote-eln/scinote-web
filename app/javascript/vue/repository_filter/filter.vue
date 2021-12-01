<template>
  <div class="filter-container">
    <div class='filter-title'>{{ filter.column.name }}</div>
    <div class="filter-element">
      <div class="filter-body">
        <component
          :is="filter.column.data_type"
          :filter="filter"
          @filter:update="updateFilter" />
      </div>
      <div class="filter-remove">
        <button class="btn btn-light icon-btn" @click="$emit('filter:delete')">
          <i class="fas fa-times-circle"></i>
        </button>
      </div>
      <hr>
    </div>
</div>
</template>

<script>
  // filter types
  import RepositoryAssetValue from 'vue/repository_filter/filters/repositoryAssetValue.vue'
  import RepositoryTextValue from 'vue/repository_filter/filters/repositoryTextValue.vue'
  import RepositoryNumberValue from 'vue/repository_filter/filters/repositoryNumberValue.vue'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'


  export default {
    name: "FilterElement",
    props: {
      filter: Object,
    },
    components: {
      DropdownSelector,
      RepositoryAssetValue,
      RepositoryTextValue,
      RepositoryNumberValue
    },
    methods: {
      updateFilter(value) {
        console.log(value);
        this.$emit('filter:update', value)
      }
    }
  }
</script>
