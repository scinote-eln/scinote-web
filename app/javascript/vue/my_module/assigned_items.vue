<template>
  <div class="bg-white px-4 my-4">
    <div class="py-4 flex items-center gap-4">
      <i ref="openHandler" @click="toggleContainer" class="sn-icon sn-icon-right cursor-pointer"></i>
      <h2 class="my-0 flex items-center gap-1">
        {{ i18n.t('my_modules.assigned_items.title') }}
        <span class="text-sn-grey-500 font-normal text-base">[{{ totalRows }}]</span>
      </h2>
      <div class="flex gap-6 ml-auto">
        <button class="btn btn-secondary" @click="openCreateItemModal=true">
          {{ i18n.t('my_modules.assigned_items.create_item') }}
        </button>
        <!-- Next block just for legacy support, JQuery not good works with Teleport -->
          <div class="hidden repository-assign"
            v-for="repository in availableRepositories"
            :key="repository.id"
            :data-table-url="repository.table_url"
            :data-assign-url-modal="repository.assign_url"
            :data-update-url-modal="repository.update_url"
            :data-repository-id="repository.id"
            :ref="`repository_${repository.id}`"
          ></div>
        <!-- End of block -->
        <GeneralDropdown position="right" @open="loadAvailableRepositories">
          <template v-slot:field>
            <button class="btn btn-secondary">
              {{ i18n.t('my_modules.assigned_items.assign_from') }}
              <span class="sn-icon sn-icon-down"></span>
            </button>
          </template>
          <template v-slot:flyout>
            <div v-if="loadingAvailableRepositories" class="flex items-center justify-center w-full h-32">
              <img src="/images/medium/loading.svg" alt="Loading" />
            </div>
            <div v-else v-for="repository in availableRepositories" :key="repository.id">
              <div class="px-3 py-2.5 hover:bg-sn-super-light-grey max-w-[320px] cursor-pointer overflow-hidden flex items-center gap-1" @click="openAssignModal(repository.id)">
                <i v-if="repository.shared"  class="sn-icon sn-icon sn-icon-users shrink-0"></i>
                <span class="truncate">{{ repository.name }}</span>
                <span v-if="repository.rows_count > 0" class="text-sn-grey-500">
                  <i class="fas fa-file-signature"></i>
                  {{ repository.rows_count }}
                </span>
              </div>
            </div>
          </template>
        </GeneralDropdown>
      </div>
    </div>
    <div ref="repositoriesContainer" class="overflow-hidden transition-all" style="max-height: 0px;">
      <div class="pl-[2.375rem] py-2.5 mb-4 flex flex-col gap-4">
        <AssignedRepository
          v-for="repository in assignedRepositories"
          :key="repository.id"
          :repository="repository"
          @recalculateContainerSize="recalculateContainerSize"
        />
      </div>
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
    myModuleId: String
  },
  components: {
    GeneralDropdown,
    AssignedRepository,
    CreateItemModal
  },
  created() {
    this.loadAssingedRepositories();
  },
  computed: {
    totalRows() {
      return this.assignedRepositories.reduce((acc, repository) => acc + repository.attributes.assigned_rows_count, 0);
    }
  },
  data() {
    return {
      availableRepositories: [],
      assignedRepositories: [],
      loadingAvailableRepositories: false,
      sectionOpened: false,
      openCreateItemModal: false
    };
  },
  methods: {
    recalculateContainerSize(offset = 0) {
      const container = this.$refs.repositoriesContainer;
      const handler = this.$refs.openHandler;

      if (this.sectionOpened) {
        container.style.maxHeight = `${container.scrollHeight + offset}px`;
        handler.classList.remove('sn-icon-right');
        handler.classList.add('sn-icon-down');
      } else {
        container.style.maxHeight = '0px';
        handler.classList.remove('sn-icon-down');
        handler.classList.add('sn-icon-right');
      }
    },
    toggleContainer() {
      this.sectionOpened = !this.sectionOpened;
      this.recalculateContainerSize();
    },
    loadAssingedRepositories() {
      axios.get(this.assignedRepositoriesUrl)
        .then((response) => {
          this.assignedRepositories = response.data.data;
        });
    },
    newCreatedRow(repositoryRowSidebarUrl) {
      this.loadAssingedRepositories();
      window.repositoryItemSidebarComponent.toggleShowHideSidebar(repositoryRowSidebarUrl, this.myModuleId, null);
    },
    openAssignModal(repositoryId) {
      const [repository] = this.$refs[`repository_${repositoryId}`];
      repository.click();
    },
    loadAvailableRepositories() {
      this.loadingAvailableRepositories = true;
      axios.get(this.avaialableRepositoriesUrl)
        .then((response) => {
          this.availableRepositories = response.data.repositories;
          this.loadingAvailableRepositories = false;
          this.recalculateContainerSize();
        });
    }
  }
};
</script>
