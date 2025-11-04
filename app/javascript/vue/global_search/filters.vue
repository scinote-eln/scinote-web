<template>
  <div class="max-w-[600px] py-3.5">
    <div class="flex flex-col pb-6 overflow-y-auto w-[calc(100%_+_1rem)] px-2 -ml-2 max-h-[calc(80vh_-_160px)]">
      <div class="sci-label mb-2" data-e2e="e2e-TX-globalSearch-filters-filterByType">{{ i18n.t('search.filters.by_type') }}</div>
      <div class="flex items-center gap-2 flex-wrap mb-6">
        <template v-for="group in searchGroups" :key="group.value">
          <button class="btn btn-secondary btn-xs"
                  ref="groupButtons"
                  :class="{'active': activeGroup === group.value}"
                  @click="setActiveGroup(group.value)"
                  :data-e2e="`e2e-BT-globalSearch-filters-${group.label.toLowerCase().replaceAll(/\s+/g, '')}`">
            {{ group.label }}
          </button>
        </template>
      </div>
      <div class="sci-label mb-2">{{ i18n.t('search.filters.by_tag') }}</div>
      <div class="grow mb-6">
        <SelectDropdown :options="tags"
                        @change="selectTags"
                        :optionRenderer="TagsDropdownRenderer"
                        :multiple="true"
                        class="grow"
                        :value="selectedTags"
                        :searchable="true"
                        :withCheckboxes="true"
                        :placeholder="i18n.t('search.filters.by_tag_placeholder')"
                        :tagsView="true">
        </SelectDropdown>
      </div>
      <div class="sci-label mb-2" data-e2e="e2e-TX-globalSearch-filters-filterByCreated">{{ i18n.t('search.filters.by_created_date') }}</div>
      <DateFilter
        :date="createdAt"
        ref="createdAtComponent"
        class="mb-6"
        @change="(v) => {this.createdAt = v}"
        e2eValue="globalSearch-filters-createdDate"
      ></DateFilter>
      <div class="sci-label mb-2" data-e2e="e2e-TX-globalSearch-filters-filterByUpdated">{{ i18n.t('search.filters.by_updated_date') }}</div>
      <DateFilter
        :date="updatedAt"
        ref="updatedAtComponent"
        class="mb-6"
        @change="(v) => {this.updatedAt = v}"
        e2eValue="globalSearch-filters-updatedDate"
      ></DateFilter>
      <template v-if="teams.length > 1">
        <div class="sci-label mb-2" data-e2e="e2e-TX-globalSearch-filters-filterByTeam">{{ i18n.t('search.filters.by_team') }}</div>
        <SelectDropdown :options="teams"
                        class="mb-6"
                        :with-checkboxes="true"
                        :clearable="true"
                        :searchable="true"
                        :multiple="true"
                        :value="selectedTeams"
                        :placeholder="i18n.t('search.filters.by_team_placeholder')"
                        @change="selectTeams"
                        e2eValue="e2e-DC-globalSearch-filters-teams" />
      </template>
      <div class="sci-label mb-2 flex items-center gap-2" data-e2e="e2e-TX-globalSearch-filters-filterByUser">
        {{ i18n.t('search.filters.by_user') }}
        <i class="sn-icon sn-icon-info" :title="i18n.t('search.filters.by_user_info')"></i>
      </div>
      <SelectDropdown :options="users"
                      class="mb-6"
                      :value="selectedUsers"
                      :optionRenderer="UsersDropdownRenderer"
                      :labelRenderer="UsersDropdownRenderer"
                      :clearable="true"
                      :searchable="true"
                      :with-checkboxes="true"
                      :multiple="true"
                      :placeholder="i18n.t('search.filters.by_user_placeholder')"
                      @change="selectUsers"
                      e2eValue="e2e-DC-globalSearch-filters-users" />
      <div class="flex items-center gap-2" data-e2e="e2e-TX-globalSearch-filters-includeArchived">
        <div class="sci-checkbox-container">
          <input type="checkbox" v-model="includeArchived" class="sci-checkbox" data-e2e="e2e-CB-globalSearch-filters-includeArchived"/>
          <span class="sci-checkbox-label"></span>
        </div>
        {{ i18n.t('search.filters.include_archived') }}
      </div>
    </div>
    <hr class="mb-6">
    <div class="flex items-center gap-6">
      <button class="btn btn-light" @click="clearFilters" data-e2e="e2e-BT-globalSearch-filters-clearFilters">{{ i18n.t('search.filters.clear') }}</button>
      <button class="btn btn-secondary ml-auto" @click="$emit('cancel')" data-e2e="e2e-BT-globalSearch-filters-cancel">{{ i18n.t('general.cancel') }}</button>
      <button class="btn btn-primary" @click="search" data-e2e="e2e-BT-globalSearch-filters-search">{{ i18n.t('general.search') }}</button>
    </div>
  </div>
</template>

<script>

import DateFilter from './filters/date.vue';
import SelectDropdown from '../shared/select_dropdown.vue';
import axios from '../../packs/custom_axios.js';
import UsersDropdownRenderer from '../shared/select_dropdown_renderers/user.vue';
import TagsDropdownRenderer from '../shared/select_dropdown_renderers/tag.vue';

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
    tagsUrl: {
      type: String,
      required: true
    },
    filters: Object,
    currentTeam: Number || String,
    searchUrl: String,
    searchQuery: String
  },
  created() {
    this.fetchTeams();
    if (this.currentTeam) {
      this.selectedTeams = [this.currentTeam];
    }

    if (this.filters) {
      this.createdAt = this.filters.created_at;
      this.updatedAt = this.filters.updated_at;
      this.selectedTeams = this.filters.teams;
      this.$nextTick(() => {
        this.selectedUsers = this.filters.users;
        this.selectedTags = this.filters.tags;
      });
      this.includeArchived = this.filters.include_archived;
      this.activeGroup = this.filters.group;
    }
  },
  watch: {
    selectedTeams() {
      this.selectedUsers = [];
      this.fetchUsers();
      this.selectedTags = [];
      this.fetchTags();
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
      selectedTags: [],
      includeArchived: true,
      teams: [],
      users: [],
      tags:[],
      TagsDropdownRenderer: TagsDropdownRenderer,
      UsersDropdownRenderer: UsersDropdownRenderer,
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
    SelectDropdown,
    UsersDropdownRenderer,
    TagsDropdownRenderer
  },
  methods: {
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
    fetchTags() {
      axios.get(this.tagsUrl, { params: { teams: this.selectedTeams } })
        .then((response) => {
          this.tags = response.data.data.map((tag) => ([parseInt(tag.id, 10), tag.name, { color: tag.color }]));
        });
    },
    selectTeams(teams) {
      if (Array.isArray(teams)) {
        this.selectedTeams = teams;
      }
    },
    selectUsers(users) {
      if (Array.isArray(users)) {
        this.selectedUsers = users;
      }
    },
    selectTags(tags) {
      if (Array.isArray(tags)) {
        this.selectedTags = tags;
      }
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
      } else {
        this.$emit('search', {
          created_at: this.createdAt,
          updated_at: this.updatedAt,
          teams: this.selectedTeams,
          users: this.selectedUsers,
          tags: this.selectedTags,
          include_archived: this.includeArchived,
          group: this.activeGroup
        });
      }
    },
    openSearchPage() {
      const params = {
        'created_at[on]': this.createdAt.on || '',
        'created_at[from]': this.createdAt.from || '',
        'created_at[to]': this.createdAt.to || '',
        'created_at[mode]': this.createdAt.mode || '',
        'updated_at[on]': this.updatedAt.on || '',
        'updated_at[from]': this.updatedAt.from || '',
        'updated_at[to]': this.updatedAt.to || '',
        'updated_at[mode]': this.updatedAt.mode || '',
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

      this.selectedTags.forEach((tag) => {
        searchParams.append('tags[]', tag);
      });

      window.location.href = `${this.searchUrl}?${searchParams.toString()}`;
    }
  }
};
</script>
