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
    <div v-if="users" class="users-filter-dropdown">
      <SelectDropdown
        :multiple="true"
        :withCheckboxes="true"
        :value="this.value"
        :options="this.users.map((i) => [i.value, i.label])"
        :fewOptionsPlaceholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryUserValue.multiple_selected')"
        :allOptionsPlaceholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryUserValue.all_selected')"
        :placeholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryUserValue.select_placeholder')"
        :e2eValue="`e2e-DC-invInventoryFilterCO-input${this.filter.column.id}`"
        @change="updateValue"
      />
    </div>
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import SelectDropdown from '../../shared/select_dropdown.vue';

import axios from '../../../packs/custom_axios.js';

import {
  repository_users_repository_path
 } from '../../../routes.js';

export default {
  name: 'RepositoryUserValue',
  mixins: [FilterMixin],
  props: {
    repositoryId: {
      type: Number,
      required: true
    }
  },
  data() {
    return {
      operators: [
        [ 'any_of', this.i18n.t('repositories.show.repository_filter.filters.operators.any_of') ],
        [ 'none_of', this.i18n.t('repositories.show.repository_filter.filters.operators.none_of') ]
      ],
      operator: 'any_of',
      value: [],
      users: null
    };
  },
  components: {
    SelectDropdown
  },
  mounted() {
    const params = {};
    if (this.filter.column.id === 'archived_by') params.archived_by = true;
    axios.get(repository_users_repository_path(this.repositoryId), { params }).then((response) => {
      this.users = response.data.users;
    });
  },
  watch: {
    value() {
      this.parameters = { user_ids: this.value };
      this.updateFilter();
    }
  },
  methods: {
    updateValue(value) {
      this.value = value;
    }
  },
  computed: {
    isBlank() {
      return (this.operator === 'any_of' && this.value.length === 0)
               || (this.filter.column.id === 'archived_by' && $('.repository-show').hasClass('active'));
    }
  }
};
</script>
