<template>
  <div>
    <div class="flex items-center gap-4 p-4 rounded bg-white mb-4">
      <div class="font-bold">{{ i18n.t('equipment_bookings.index.show_calendar') }}</div>
      <div class="w-80">
        <SelectDropdown
          :options="repositories"
          :searchable="true"
          :value="selectedRepository"
          @change="selectedRepository = $event"
        ></SelectDropdown>
      </div>
    </div>

    <div class="p-4 rounded bg-white h-[calc(100vh_-_18rem)] flex" >
      <Filters
        v-if="selectedRepository"
        :repository-id="selectedRepository"
        :filters="filters"
        :permissions="permissions"
        @update:filters="filters = $event"
        @event:created="loadEvents += 1"
      ></Filters>
      <CalendarView
        v-if="selectedRepository"
        :repositoryId="selectedRepository"
        :permissions="permissions"
        :loadEvents="loadEvents"
        :filters="filters"
      ></CalendarView>
    </div>

  </div>
</template>

<script>
import SelectDropdown from '../shared/select_dropdown.vue';
import axios from '../../packs/custom_axios.js';
import CalendarView from './calendar_view.vue';
import Filters from './filters.vue';

import {
  list_repositories_path,
  permissions_repository_path,
} from '../../routes.js';

export default {
  name: 'EquipmentBookings',
  data() {
    return {
      repositories: [],
      selectedRepository: null,
      loadEvents: 0,
      permissions: {},
      filters: {
        sub_types: {
          calibration: true,
          maintenance: true,
          usage: true,
          no_type: true
        },
        subject_ids: [],
        assigned_users: []
      }
    };
  },
  components: {
    SelectDropdown,
    Filters,
    CalendarView
  },
  watch: {
    selectedRepository() {
      this.loadPermissions();
    }
  },
  mounted() {
    this.fetchRepositories();
  },
  computed: {
    listRepositoriesUrl() {
      return list_repositories_path
    },
    permissionsUrl() {
      if (this.selectedRepository) {
        return permissions_repository_path(this.selectedRepository);
      }
    }
  },
  methods: {
    loadPermissions() {
      if (this.permissionsUrl) {
        axios.get(this.permissionsUrl)
          .then(response => {
            this.permissions = response.data;
          })
      }
    },
    fetchRepositories() {
      axios
      axios.get(this.listRepositoriesUrl())
        .then(response => {
          this.repositories = response.data.data;
          this.$nextTick(() => {
            if (this.repositories.length > 0) {
              this.selectedRepository = this.repositories[0][0];
            }
          });
        })
    }
  },

};
</script>
