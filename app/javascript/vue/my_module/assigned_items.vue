<template>
  <div class="pt-4">
    <div class="p-4 bg-white sticky top-[70px] z-[100] rounded flex items-center justify-between mb-4">
      <div v-if="assignedRepositories.length == 0 && !loadingRepositories" class="text-sn-grey-700 text-sm">
        <template v-if="canAssign">
          {{  i18n.t('my_modules.repository.no_assigned_items_can_assign') }}
        </template>
        <template v-else>
          {{  i18n.t('my_modules.repository.no_assigned_items') }}
        </template>
      </div>
      <div class="ml-auto flex items-center gap-4">
        <button
          v-if="canAssign"
          class="btn btn-secondary"
        >
         <i class="sn-icon sn-icon-new-task"></i>
         {{ i18n.t('my_modules.repository.assign_items') }}
        </button>
        <button
          v-if="canAssign"
          class="btn btn-secondary"
        >
          <i class="sn-icon sn-icon-create-item"></i>
          {{ i18n.t('my_modules.repository.create_item') }}
        </button>
        <template v-if="assignedRepositories.length > 0">
          <button :title="i18n.t('protocols.steps.collapse_label')" v-if="!repositoriesCollapsed" class="btn btn-secondary icon-btn xl:!px-4" @click="collapseRepositories" tabindex="0">
            <i class="sn-icon sn-icon-collapse-all"></i>
            <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.collapse_label") }}</span>
          </button>
          <button v-else  :title="i18n.t('protocols.steps.expand_label')" class="btn btn-secondary icon-btn xl:!px-4" @click="expandRepositories" tabindex="0">
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
        :myModuleId="myModuleId"
      />
    </div>
    <Teleport to="body">
      <CreateItemModal
        v-if="openCreateItemModal"
        :repositoriesUrl="repositoriesUrl"
        :myModuleId="myModuleId"
        @tableReloaded="newCreatedRow"
        @close="openCreateItemModal = false"/>
    </Teleport>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import GeneralDropdown from '../shared/general_dropdown.vue';
import AssignedRepository from './assigned_items/repository.vue';
import CreateItemModal from './assigned_items/modals/new_item.vue';

export default {
  name: 'AssignedItems',
  props: {
    avaialableRepositoriesUrl: String,
    assignedRepositoriesUrl: String,
    repositoriesUrl: String,
    myModuleId: String,
    canAssign: Boolean
  },
  components: {
    GeneralDropdown,
    AssignedRepository,
    CreateItemModal
  },
  created() {
    this.loadAssingedRepositories();
  },
  data() {
    return {
      assignedRepositories: [],
      openCreateItemModal: false,
      repositoriesCollapsed: false,
      loadingRepositories: true
    };
  },
  methods: {
    loadAssingedRepositories() {
      axios.get(this.assignedRepositoriesUrl)
        .then((response) => {
          this.assignedRepositories = response.data.data;
          this.loadingRepositories = false;
        });
    },
    newCreatedRow(repositoryRowSidebarUrl) {
      this.loadAssingedRepositories();
      window.repositoryItemSidebarComponent.toggleShowHideSidebar(repositoryRowSidebarUrl, this.myModuleId, null);
    },
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
