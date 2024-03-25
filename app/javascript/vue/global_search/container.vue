<template>
  <div class="content-pane flexible with-grey-background">
    <div class="content-header">
      <div class="title-row">
        <h1 class="mt-0">
          {{ i18n.t('search.index.results_title_html', { query: localQuery }) }}
        </h1>
      </div>
    </div>
    <div class="bg-white rounded p-4 flex gap-2.5 items-center mb-4 sticky top-0">
      <div class="left-icon sci-input-container-v2 w-72 input-sm" :title="i18n.t('nav.search')">
        <input ref="searchField" type="text" class="!pr-9" :value="localQuery" @change="changeQuery" :placeholder="i18n.t('nav.search')"/>
        <i class="sn-icon sn-icon-search"></i>
        <i v-if="localQuery.length > 0" class="sn-icon cursor-pointer sn-icon-close absolute right-0 -top-0.5" @click="localQuery = ''"></i>
      </div>
      <div class="flex items-center gap-2.5">
        <button class="btn btn-secondary btn-sm" :class="{'active': activeGroup == 'ExperimentsComponent'}" @click="setActiveGroup('ExperimentsComponent')">
          {{ i18n.t('search.index.experiments') }}
        </button>
        <button class="btn btn-secondary btn-sm" :class="{'active': activeGroup == 'MyModulesComponent'}" @click="setActiveGroup('MyModulesComponent')">
          {{ i18n.t('search.index.tasks') }}
        </button>
        <button class="btn btn-secondary btn-sm" :class="{'active': activeGroup == 'ResultsComponent'}" @click="setActiveGroup('ResultsComponent')">
          {{ i18n.t('search.index.task_results') }}
        </button>
      </div>
      <button class="btn btn-light btn-sm">
        <i class="sn-icon sn-icon-search-options"></i>
        {{ i18n.t('search.index.more_search_options') }}
      </button>
      <template v-if="activeGroup">
        <div class="h-4 w-[1px] bg-sn-grey"></div>
        <button class="btn btn-light btn-sm" @click="activeGroup = null">
          <i class="sn-icon sn-icon-close"></i>
          {{ i18n.t('search.index.clear_filters') }}
        </button>
      </template>
    </div>
    <template v-for="group in searchGroups">
      <component
        :key="group"
        :is="group"
        v-if="activeGroup === group || !activeGroup"
        :selected="activeGroup === group"
        :query="localQuery"
        :searchUrl="searchUrl"
        @selectGroup="setActiveGroup"
      />
    </template>
  </div>
</template>

<script>
import FoldersComponent from './groups/folders.vue';
import ProjectsComponent from './groups/projects.vue';
import ExperimentsComponent from './groups/experiments.vue';
import MyModulesComponent from './groups/my_modules.vue';
import MyModuleProtocolsComponent from './groups/my_module_protocols.vue';
import ResultsComponent from './groups/results.vue';
import AssetsComponent from './groups/assets.vue';
import RepositoryRowsComponent from './groups/repository_rows.vue';
import ProtocolsComponent from './groups/protocols.vue';
import LabelTemplatesComponent from './groups/label_templates.vue';
import ReportsComponent from './groups/reports.vue';

export default {
  name: 'GlobalSearch',
  props: {
    query: {
      type: String,
      required: true
    },
    searchUrl: {
      type: String,
      required: true
    }
  },
  components: {
    FoldersComponent,
    ProjectsComponent,
    ExperimentsComponent,
    MyModulesComponent,
    MyModuleProtocolsComponent,
    ResultsComponent,
    AssetsComponent,
    RepositoryRowsComponent,
    ProtocolsComponent,
    LabelTemplatesComponent,
    ReportsComponent
  },
  data() {
    return {
      localQuery: this.query,
      activeGroup: null,
      searchGroups: [
        'FoldersComponent',
        'ProjectsComponent',
        'ExperimentsComponent',
        'MyModulesComponent',
        'MyModuleProtocolsComponent',
        'ResultsComponent',
        'AssetsComponent',
        'RepositoryRowsComponent',
        'ProtocolsComponent',
        'LabelTemplatesComponent',
        'ReportsComponent'
      ]
    };
  },
  methods: {
    setActiveGroup(group) {
      if (group === this.activeGroup) {
        this.activeGroup = null;
      } else {
        this.activeGroup = group;
      }
    },
    changeQuery(event) {
      this.localQuery = event.target.value;
    }
  }
};
</script>
