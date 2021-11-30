<template>
  <div class="filter-container">
    <div class='filter-title'>{{ filter.column.name }}</div>
    <div class="filter-element">
      <div class="filter-body">
        <component
<<<<<<< HEAD
          :is="filter.column.data_type"
          :filter="filter"
          @filter:update="updateFilter" />
=======
          :is="type"
          :filter="filter" />
>>>>>>> aa6ba18d8 (Add basic structure for text filter [SCI-6213])
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
<<<<<<< HEAD
  // filter types
  import RepositoryAssetValue from 'vue/repository_filter/filters/repositoryAssetValue.vue'

  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
=======
  import RepositoryTextValue from 'vue/repository_filter/filters/repositoryTextValue.vue'
>>>>>>> aa6ba18d8 (Add basic structure for text filter [SCI-6213])

  export default {
    name: "FilterElement",
    props: {
      filter: Object,
    },
    data() {
      return {
        type: this.filter.column.data_type
      }
    },
    components: {
<<<<<<< HEAD
      DropdownSelector,
      RepositoryAssetValue
=======
      RepositoryTextValue
>>>>>>> aa6ba18d8 (Add basic structure for text filter [SCI-6213])
    },
    methods: {
      updateFilter(value) {
        this.$emit('filter:update', value)
      }
    }
  }
</script>
