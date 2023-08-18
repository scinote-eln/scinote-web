<template>
  <div class="result-toolbar p-3 flex justify-between rounded-md bg-sn-white">
    <div class="result-toolbar__left">
      <button class="btn btn-secondary" @click="$emit('newResult')">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('my_modules.results.add_label') }}
      </button>
    </div>
    <div class="result-toolbar__right flex items-center" @click="$emit('expandAll')">
      <button class="btn btn-secondary mr-3">
        {{ i18n.t('my_modules.results.expand_label') }}
      </button>
      <button class="btn btn-secondary mr-3" @click="$emit('collapseAll')">
        {{ i18n.t('my_modules.results.collapse_label') }}
      </button>

      <button class="btn btn-light icon-btn mr-3">
        <i class="sn-icon sn-icon-filter"></i>
      </button>

      <div class="dropdown">
        <button class="dropdown-toggle btn btn-light icon-btn mr-3"  id="sortDropdown" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
          <i class="sn-icon sn-icon-sort"></i>
        </button>
        <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="sortDropdown">
          <li v-for="sort in sorts" :key="sort">
            <a class="cursor-pointer" @click="setSort(sort)">
              {{ i18n.t(`my_modules.results.sorts.${sort}`)}}
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
  const SORTS = [
    'updated_at_asc',
    'updated_at_desc',
    'created_at_asc',
    'created_at_desc',
    'name_asc',
    'name_desc'
  ];

  export default {
    name: 'ResultsToolbar',
    props: {
      sort: { type: String, required: true }
    },
    created() {
      this.sorts = SORTS;
    },
    methods: {
      setSort(sort) {
        this.$emit('setSort', sort);
      }
    }
  }
</script>
