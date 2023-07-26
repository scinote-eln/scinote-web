<template>
  <div class="sn-list-toolbar flex justify-between">
    <div class="sn-list-toolbar__left">
      <a v-for="action in actions" :key="action.name"
           class="btn mr-1"
           :class="{ 'btn-primary': action.primary, 'btn-light': !action.primary }"
           :href="(['link', 'remote-modal']).includes(action.type) ? action.path : '#'"
           :data-url="action.path"
           :data-action="action.type"
      >
        <i class="mr-1" :class="action.icon"></i>
        <span class="sn-list-toolbar__button-text">{{ action.label }}</span>
      </a>
    </div>
    <div class="sn-list-toolbar__center flex">
      <Select
        class="mr-1 prevent-shrink"
        :value="view"
        ref="viewSelector"
        @change="changeView"
        :options="viewOptions" />
      <Select
        class="prevent-shrink"
        :value="archived"
        ref="archivedSelector"
        @change="changeArchived"
        :options="archivedOptions" />
    </div>
    <div class="sn-list-toolbar__right flex">
      <div v-if="filters">
        <FilterDropdown :filters="filters" @applyFilters="applyFilters" />
      </div>
      <div class="dropdown sort-menu" :title="i18n.t('general.sort.title')">
        <button class="btn btn-light btn-black icon-btn dropdown-toggle" type="button" id="sortMenu" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
          <span><i class="sn-icon sn-icon-sort-down"></i></span>
        </button>
        <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="sortMenu">
          <template v-for="(sortOption, i) in sortOptions">
            <li v-if="sortOption[0] === '|'" class="divider" :key="'divider' + i">
            </li>
            <li v-else :key="sortOption[0]">
              <a
                :class="{ 'selected': sort === sortOption[0] }"
                :data-sort="sortOption[0]"
                v-html="sortOption[1]"
                @click="changeSort(sortOption[0])">
              </a>
            </li>
          </template>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
  import Select from '../shared/select.vue';
  import FilterDropdown from '../shared/filter_dropdown.vue';

  export default {
    name: 'ListToolbar',
    props: {
      url: { type: String, required: true }
    },
    components: { Select, FilterDropdown },
    data() {
      return {
        loading: false,
        actions: null,
        views: null,
        view: null,
        sorts: null,
        sort: null,
        archived: null,
        filters: null,
        filterValues: null,
        viewChangeCallback: null,
        archivedChangeCallback: null,
        sortChangeCallback: null,
        filterChangeCallback: null
      }
    },
    created() {
      window.listToolbarComponent = this;
      this.loading = true;
      $.get(this.url, (data) => {
        this.actions = data.actions;
        this.views = data.views;
        this.view = data.view;
        this.sorts = data.sorts;
        this.sort = data.sort;
        this.filters = data.filters;
        this.archived = data.archived;
        this.loading = false;
      });
    },
    beforeDestroy() {
      delete window.listToolbarComponent;
    },
    computed: {
      viewOptions() {
        if (!this.views) return [];

        return this.views.map((v) => [v, this.i18n.t(`toolbar.${v}_view`)]);
      },
      sortOptions() {
        if (!this.sorts) return [];

        return this.sorts.map((s) => [s, this.i18n.t(`general.sort.${s}_html`)]);
      },
      archivedOptions() {
        return [
          ['true', this.i18n.t('toolbar.archived_state')],
          ['false', this.i18n.t('toolbar.active_state')]
        ]
      }
    },
    methods: {
      changeView(value) {
        this.view = value;
        if (this.viewChangeCallback) {
          return this.viewChangeCallback(value);
        }

        this.reloadList();
      },
      changeSort(value) {
        this.sort = value;
        if (this.sortChangeCallback) {
          return this.sortChangeCallback(value);
        }

        this.reloadList();
      },
      changeArchived(value) {
        this.archived = value;
        if (this.archivedChangeCallback) {
          return this.archivedChangeCallback(value);
        }

        this.reloadList();
      },
      applyFilters(filterValues) {
        this.filterValues = filterValues;

        if (this.filterChangeCallback) {
          return this.filterChangeCallback(filterValues);
        }
      },
      reloadList() {
        Turbolinks.visit(`?view=${this.view}&archived=${this.archived}&sort=${this.sort}`);
      }
    }
  }
</script>
