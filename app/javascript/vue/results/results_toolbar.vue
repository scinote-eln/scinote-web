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
          <li>
            <a class="cursor-pointer" @click="setSort('updated_at_asc')">
              {{ i18n.t('my_modules.results.sorts.updated_at_asc')}}
            </a>
          </li>
          <li>
            <a class="cursor-pointer" @click="setSort('updated_at_desc')">
              {{ i18n.t('my_modules.results.sorts.updated_at_desc')}}
            </a>
          </li>
          <li>
            <a class="cursor-pointer" @click="setSort('created_at_asc')">
              {{ i18n.t('my_modules.results.sorts.created_at_asc')}}
            </a>
          </li>
          <li>
            <a class="cursor-pointer" @click="setSort('created_at_desc')">
              {{ i18n.t('my_modules.results.sorts.created_at_desc')}}
            </a>
          </li>
          <li>
            <a class="cursor-pointer" @click="setSort('name_asc')">
              {{ i18n.t('my_modules.results.sorts.name_asc')}}
            </a>
          </li>
          <li>
            <a class="cursor-pointer" @click="setSort('name_desc')">
              {{ i18n.t('my_modules.results.sorts.name_desc')}}
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'ResultsToolbar',
    props: {
      sort: { type: String, required: true }
    },
    methods: {
      setSort(sort) {
        this.$emit('setSort', sort);
      }
    }
  }
</script>
