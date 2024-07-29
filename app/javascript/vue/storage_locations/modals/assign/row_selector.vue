<template>
  <div>
    <div class="mb-4">
      <div class="sci-label">{{ i18n.t(`storage_locations.show.assign_modal.inventory`) }}</div>
      <SelectDropdown
        :optionsUrl="repositoriesUrl"
        placeholder="Select inventory"
        :searchable="true"
        @change="selectedRepository = $event"
      ></SelectDropdown>
    </div>
    <div>
      <div class="sci-label">{{ i18n.t(`storage_locations.show.assign_modal.item`) }}</div>
      <SelectDropdown
        :disabled="!selectedRepository"
        :optionsUrl="rowsUrl"
        :urlParams="{ repository_id: selectedRepository }"
        placeholder="Select item"
        :searchable="true"
        @change="selectedRow= $event"
      ></SelectDropdown>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../../shared/select_dropdown.vue';
import {
  list_team_repositories_path,
  rows_list_team_repositories_path
} from '../../../../routes.js';

export default {
  name: 'RowSelector',
  components: {
    SelectDropdown
  },
  created() {
    this.teamId = document.body.dataset.currentTeamId;
  },
  watch: {
    selectedRepository() {
      this.selectedRow = null;
    },
    selectedRow() {
      this.$emit('change', this.selectedRow);
    }
  },
  computed: {
    repositoriesUrl() {
      return list_team_repositories_path(this.teamId);
    },
    rowsUrl() {
      if (!this.selectedRepository) {
        return null;
      }

      return rows_list_team_repositories_path(this.teamId);
    }
  },
  data() {
    return {
      selectedRepository: null,
      selectedRow: null,
      teamId: null
    };
  }
};
</script>
