<template>
  <div>
    <div v-if="repositories.length > 0" class="p-4 rounded bg-white h-[calc(100vh_-_12rem)] flex" >
      <Filters
        v-if="selectedRepository"
        :repository-id="selectedRepository"
        :filters="filters"
        :permissions="permissions"
        :repositories="repositories"
        @update:filters="filters = $event"
        @update:repository="selectedRepository = $event"
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
    <div v-else-if="!loadingRepositories" class="h-[calc(100vh_-_12rem)] flex items-center justify-center flex-col gap-4" >
      <h2 class="text-sn-grey">{{ i18n.t('equipment_bookings.index.no_repositories') }}</h2>
      <a :href="repositoriesUrl" class="btn btn-secondary">
        {{ i18n.t('equipment_bookings.index.go_to_repositories') }}
      </a>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../shared/select_dropdown.vue';
import StateMixin from '../mixins/user_state_mixin.js';
import axios from '../../packs/custom_axios.js';
import CalendarView from './calendar_view.vue';
import Filters from './filters.vue';

import {
  list_repositories_path,
  permissions_repository_path,
  repositories_path
} from '../../routes.js';

export default {
  name: 'EquipmentBookings',
  data() {
    return {
      loadingRepositories: true,
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
        assigned_user_ids: []
      }
    };
  },
  mixins: [StateMixin],
  components: {
    SelectDropdown,
    Filters,
    CalendarView
  },
  watch: {
    selectedRepository() {
      this.loadPermissions();

      this.filters = {
        sub_types: {
          calibration: true,
          maintenance: true,
          usage: true,
          no_type: true
        },
        subject_ids: [],
        assigned_user_ids: []
      }

      this.setUserState('equipment_bookings_selected_repository', {repository_id: this.selectedRepository});
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
    },
    repositoriesUrl() {
      return repositories_path();
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
          this.$nextTick(async() => {
            const savedRepositoryState = await this.getUserState('equipment_bookings_selected_repository');

            if (savedRepositoryState && this.repositories.some(repo => repo[0] === savedRepositoryState.repository_id)) {
              this.selectedRepository = savedRepositoryState.repository_id;
            } else if (this.repositories.length > 0) {
              this.selectedRepository = this.repositories[0][0];
            }

            this.loadingRepositories = false;
          });
        })
    }
  },

};
</script>
