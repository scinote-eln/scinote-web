<template>
  <div class="max-w-[600px] p-3.5">
    <div class="sci-label mb-2">{{ i18n.t('search.filters.by_type') }}</div>
    <div class="flex items-center gap-2 flex-wrap mb-6">
      <template v-for="group in searchGroups" :key="group.value">
        <button class="btn btn-secondary btn-xs"
                :class="{'active': activeGroup === group.value}"
                @click="setActiveGroup(group.value)">
          {{ group.label }}
        </button>
      </template>
    </div>
    <div class="sci-label mb-2">{{ i18n.t('search.filters.by_created_date') }}</div>
    <DateFilter
      :date="createdAt"
      ref="createdAtComponent"
      class="mb-6"
      @change="(v) => {this.createdAt = v}"
    ></DateFilter>
    <div class="sci-label mb-2">{{ i18n.t('search.filters.by_updated_date') }}</div>
    <DateFilter
      :date="updatedAt"
      ref="updatedAtComponent"
      class="mb-6"
      @change="(v) => {this.updatedAt = v}"
    ></DateFilter>
    <div class="sci-label mb-2">{{ i18n.t('search.filters.by_team') }}</div>
    <SelectDropdown :options="teams"
                    class="mb-6"
                    :with-checkboxes="true"
                    :clearable="true"
                    :multiple="true"
                    :value="selectedTeams"
                    @change="(v) => {selectedTeams = v}" />
    <div class="sci-label mb-2">{{ i18n.t('search.filters.by_user') }}</div>
    <SelectDropdown :options="users"
                    class="mb-6"
                    :value="selectedUsers"
                    :optionRenderer="userRenderer"
                    :labelRenderer="userRenderer"
                    :clearable="true"
                    :with-checkboxes="true"
                    :multiple="true"
                    @change="(v) => {selectedUsers = v}" />
    <div class="flex items-center gap-2">
      <div class="sci-checkbox-container">
        <input type="checkbox" v-model="includeArchived" class="sci-checkbox" />
        <span class="sci-checkbox-label"></span>
      </div>
      {{ i18n.t('search.filters.include_archived') }}
    </div>
    <hr class="my-6">
    <div class="flex items-center gap-6">
      <button class="btn btn-light" @click="clearFilters">{{ i18n.t('search.filters.clear') }}</button>
      <button class="btn btn-secondary ml-auto" @click="$emit('cancel')">{{ i18n.t('general.cancel') }}</button>
      <button class="btn btn-primary" @click="search" >{{ i18n.t('general.search') }}</button>
    </div>
  </div>
</template>

<script>

import DateFilter from './filters/date.vue';
import SelectDropdown from '../shared/select_dropdown.vue';
import axios from '../../packs/custom_axios.js';

export default {
  name: 'SearchFilters',
  props: {
    teamsUrl: {
      type: String,
      required: true
    },
    usersUrl: {
      type: String,
      required: true
    },
    currentTeam: Number,
    searchUrl: String,
    searchQuery: String
  },
  created() {
    this.fetchTeams();
    if (this.currentTeam) {
      this.selectedTeams = [this.currentTeam];
    }
  },
  watch: {
    selectedTeams() {
      this.selectedUsers = [];
      this.fetchUsers();
    }
  },
  data() {
    return {
      activeGroup: null,
      createdAt: {
        on: null,
        from: null,
        to: null
      },
      updatedAt: {
        on: null,
        from: null,
        to: null
      },
      selectedTeams: [],
      selectedUsers: [],
      includeArchived: true,
      teams: [],
      users: [],
      searchGroups: [
        { value: 'FoldersComponent', label: this.i18n.t('search.index.folders') },
        { value: 'ProjectsComponent', label: this.i18n.t('search.index.projects') },
        { value: 'ExperimentsComponent', label: this.i18n.t('search.index.experiments') },
        { value: 'MyModulesComponent', label: this.i18n.t('search.index.tasks') },
        { value: 'MyModuleProtocolsComponent', label: this.i18n.t('search.index.task_protocols') },
        { value: 'ResultsComponent', label: this.i18n.t('search.index.task_results') },
        { value: 'AssetsComponent', label: this.i18n.t('search.index.files') },
        { value: 'RepositoryRowsComponent', label: this.i18n.t('search.index.inventory_items') },
        { value: 'ProtocolsComponent', label: this.i18n.t('search.index.protocol_templates') },
        { value: 'LabelTemplatesComponent', label: this.i18n.t('search.index.label_templates') },
        { value: 'ReportsComponent', label: this.i18n.t('search.index.reports') }
      ]
    };
  },
  components: {
    DateFilter,
    SelectDropdown
  },
  methods: {
    userRenderer(option) {
      return `<div class="flex items-center gap-2">
                <img src="${option[2].avatar_url}" class="rounded-full w-6 h-6" />
                <div title="${option[1]}" class="truncate">${option[1]}</div>
              </div>`;
    },
    setActiveGroup(group) {
      if (group === this.activeGroup) {
        this.activeGroup = null;
      } else {
        this.activeGroup = group;
      }
    },
    fetchTeams() {
      axios.get(this.teamsUrl)
        .then((response) => {
          this.teams = response.data.data.map((team) => ([parseInt(team.id, 10), team.attributes.name]));
        });
    },
    fetchUsers() {
      axios.get(this.usersUrl, { params: { teams: this.selectedTeams } })
        .then((response) => {
          this.users = response.data.data.map((user) => ([parseInt(user.id, 10), user.attributes.name, { avatar_url: user.attributes.avatar_url }]));
        });
    },
    clearFilters() {
      this.createdAt = {
        on: null,
        from: null,
        to: null
      };
      this.updatedAt = {
        on: null,
        from: null,
        to: null
      };
      this.$refs.createdAtComponent.selectedOption = 'on';
      this.$refs.updatedAtComponent.selectedOption = 'on';
      this.selectedTeams = [];
      this.selectedUsers = [];
      this.includeArchived = false;
      this.activeGroup = null;
    },
    search() {
      if (this.searchUrl) {
        this.openSearchPage();
      }
    },
    openSearchPage() {
      const params = {
        'created_at[on]': this.createdAt.on || '',
        'created_at[from]': this.createdAt.from || '',
        'created_at[to]': this.createdAt.to || '',
        'updated_at[on]': this.updatedAt.on || '',
        'updated_at[from]': this.updatedAt.from || '',
        'updated_at[to]': this.updatedAt.to || '',
        include_archived: this.includeArchived,
        group: this.activeGroup || '',
        q: this.searchQuery
      };
      const searchParams = new URLSearchParams(params);

      this.selectedTeams.forEach((team) => {
        searchParams.append('teams[]', team);
      });

      this.selectedUsers.forEach((user) => {
        searchParams.append('users[]', user);
      });

      window.location.href = `${this.searchUrl}?${searchParams.toString()}`;
    }
  }
};
</script>
