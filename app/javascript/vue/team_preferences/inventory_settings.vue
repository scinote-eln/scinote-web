<template>
  <div class="flex flex-col bg-sn-white gap-4 p-4 w-full rounded mb-5">
    <div class="flex flex-col gap-1">
      <h5 class="m-0" data-e2e="e2e-TX-workspaceSettings-title-inventorySettings">
        {{ i18n.t('users.settings.teams.inventory_settings.title') }}
      </h5>
      <p class="m-0 text-sn-dark-grey" data-e2e="e2e-TX-workspaceSettings-description-inventorySettings">
        {{ i18n.t('users.settings.teams.inventory_settings.description') }}
      </p>
    </div>
    <div class="flex items-center gap-4 max-w-3xl">
      <div class="grow min-w-0">
        <SelectDropdown
          :options="repositories"
          :value="selectedRepositoryId"
          :searchable="true"
          :disabled="loading || repositories.length === 0"
          :placeholder="placeholder"
          e2eValue="e2e-DD-workspaceSettings-inventorySettings-inventory"
          @change="(value) => selectedRepositoryId = value"
        />
      </div>
      <button
        type="button"
        class="btn btn-secondary shrink-0"
        :disabled="!selectedRepositoryId"
        data-e2e="e2e-BT-workspaceSettings-inventorySettings-goToInventory"
        @click="goToInventory"
      >
        {{ i18n.t('users.settings.teams.inventory_settings.go_to_inventory') }}
      </button>
    </div>
  </div>
</template>

<script>
/* global HelperModule */
import axios from '../../packs/custom_axios.js';
import SelectDropdown from '../shared/select_dropdown.vue';
import {
  inventory_settings_repositories_users_settings_team_path,
  repository_path
} from '../../routes.js';

export default {
  name: 'InventorySettings',
  components: {
    SelectDropdown
  },
  props: {
    teamId: {
      type: [Number, String],
      required: true
    }
  },
  data() {
    return {
      repositories: [],
      loading: true,
      selectedRepositoryId: null
    };
  },
  computed: {
    placeholder() {
      if (!this.loading && this.repositories.length === 0) {
        return this.i18n.t('users.settings.teams.inventory_settings.no_inventories');
      }

      return this.i18n.t('users.settings.teams.inventory_settings.select_placeholder');
    }
  },
  created() {
    this.fetchRepositories();
  },
  methods: {
    fetchRepositories() {
      axios
        .get(inventory_settings_repositories_users_settings_team_path({ id: this.teamId }))
        .then(({ data }) => {
          this.repositories = data.data || [];
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
        })
        .finally(() => {
          this.loading = false;
        });
    },
    goToInventory() {
      if (!this.selectedRepositoryId) return;

      window.open(repository_path(this.selectedRepositoryId, { open_manage_columns: true }), '_blank', 'noopener');
    }
  }
};
</script>
