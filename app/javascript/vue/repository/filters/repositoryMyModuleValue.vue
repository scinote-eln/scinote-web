<template>
  <div class="filter-attributes">
    <div class="operator-selector">
      <SelectDropdown
        :searchable="false"
        :options="this.operators"
        :value="this.operator"
        :e2eValue="`e2e-DD-invInventoryFilterCO-option${this.filter.column.id}`"
        @change="updateOperator"
      />
    </div>
    <div class="max-w-[200px]">
      <SelectDropdown
        :clearable="false"
        :options="this.projects"
        :value="this.selectedProject"
        @change="updateSelectedProject"
      />
    </div>
    <SelectDropdown
      :disabled="this.myModules.length === 0"
      :options="this.myModules"
      :value="this.value"
      :multiple="true"
      :withCheckboxes="true"
      :fewOptionsPlaceholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.multiple_selected')"
      :allOptionsPlaceholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.all_selected')"
      :placeholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.select_placeholder')"
      @change="updateValue"

    />
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import SelectDropdown from '../../shared/select_dropdown.vue';
import { update } from 'lodash';

export default {
  name: 'RepositoryMyModuleValue',
  mixins: [FilterMixin],
  data() {
    return {
      operators: [
        [ 'any_of', this.i18n.t('repositories.show.repository_filter.filters.operators.any_of') ],
        [ 'all_of', this.i18n.t('repositories.show.repository_filter.filters.operators.all_of') ],
        [ 'none_of', this.i18n.t('repositories.show.repository_filter.filters.operators.none_of') ]
      ],
      operator: 'any_of',
      value: [],
      selectedProject: null
    };
  },
  components: {
    SelectDropdown
  },
  watch: {
    value() {
      this.parameters = { my_module_ids: this.value };
      this.updateFilter();
    }
  },
  methods: {
    updateValue(value) {
      this.value = value;
    },
    updateSelectedProject(value) {
      this.selectedProject = value;
    }
  },
  computed: {
    isBlank() {
      return this.operator == 'any_of' && this.value.length == 0;
    },
    projects() {
      let projects = [];
      this.my_modules.forEach((project, index) => {
        projects.push([
          index,
          project.label
        ]);
      });

      return projects;
    },
    myModules() {
      if (!this.my_modules) return [];

      if (this.my_modules[this.selectedProject]) {
        return this.my_modules[this.selectedProject].options.map((i) => [i.value, i.label]);
      }
      return [];
    }
  }
};
</script>
