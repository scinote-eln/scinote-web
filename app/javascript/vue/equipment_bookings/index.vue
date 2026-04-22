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
        @update:filters="filters = $event"
      ></Filters>
    </div>

  </div>
</template>

<script>
import SelectDropdown from '../shared/select_dropdown.vue';
import axios from '../../packs/custom_axios.js';
import Filters from './filters.vue';

import {
  list_repositories_path,
} from '../../routes.js';

export default {
  name: 'EquipmentBookings',
  data() {
    return {
      repositories: [],
      selectedRepository: null,
      filters: {
        types: {
          calibration: true,
          maintenance: true,
          usage: true,
          no_type: true
        },
        assignedRepositoryRows: [],
        assignedUsers: []
      }
    };
  },
  components: {
    SelectDropdown,
    Filters
  },
  mounted() {
    this.fetchRepositories();
  },
  computed: {
    listRepositoriesUrl() {
      return list_repositories_path
    }
  },
  methods: {
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
