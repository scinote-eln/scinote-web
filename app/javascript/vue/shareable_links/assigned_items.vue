<template>
  <div class="pt-4">
    <div class="p-4 bg-white sticky top-[70px] z-[100] rounded flex items-center justify-between mb-4">
      <div v-if="assignedRepositories.length == 0" class="text-sn-grey-700 text-sm">
        {{  i18n.t('my_modules.repository.no_assigned_items') }}
      </div>
      <div class="ml-auto flex items-center gap-4">
        <template v-if="assignedRepositories.length > 0">
          <button :title="i18n.t('protocols.steps.collapse_label')" v-if="!repositoriesCollapsed" class="btn btn-secondary icon-btn xl:!px-4" @click="collapseRepositories" tabindex="0">
            <i class="sn-icon sn-icon-collapse-all"></i>
            <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.collapse_label") }}</span>
          </button>
          <button v-else :title="i18n.t('protocols.steps.expand_label')" class="btn btn-secondary icon-btn xl:!px-4" @click="expandRepositories" tabindex="0">
            <i class="sn-icon sn-icon-expand-all"></i>
            <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.expand_label") }}</span>
          </button>
        </template>
      </div>
    </div>
    <div>
      <AssignedRepository
        v-for="repository in assignedRepositories"
        :key="repository.id"
        ref="assignedRepositories"
        :repository="repository"
        :myModuleUuid="myModuleUuid"
      />
    </div>
  </div>
</template>

<script>
import AssignedRepository from './assigned_items/repository.vue';

export default {
  name: 'AssignedItems',
  props: {
    assignedRepositories: Array,
    myModuleUuid: String
  },
  components: {
    AssignedRepository
  },
  data() {
    return {
      repositoriesCollapsed: true,
    };
  },
  methods: {
    collapseRepositories() {
      this.repositoriesCollapsed = true;
      this.$refs.assignedRepositories.forEach((repositoryComponent) => {
        repositoryComponent.sectionOpened = false;
        repositoryComponent.recalculateContainerSize();
      });
    },
    expandRepositories() {
      this.repositoriesCollapsed = false;
      this.$refs.assignedRepositories.forEach((repositoryComponent) => {
        repositoryComponent.sectionOpened = true;
        repositoryComponent.recalculateContainerSize();
      });
    }
  }
};
</script>
