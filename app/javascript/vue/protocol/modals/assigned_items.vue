<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" style="width: 90vw;">
      <div class="modal-content" data-e2e="e2e-MD-protocol-assignedItems">
        <div class="modal-header">
          <div class="w-48 flex justify-end">
            <button
              type="button"
              class="close"
              data-dismiss="modal"
              aria-label="Close"
              data-e2e="e2e-BT-protocol-assignedItemsModal-close"
            >
              <i class="sn-icon sn-icon-close"></i>
            </button>
          </div>
          <div class="mx-auto flex items-center gap-2">
            <template v-if="selectedRepository">
              {{ i18n.t('my_modules.repository.assigned_items_modal.inventory') }}
              <GeneralDropdown  ref="addFieldDropdown" class="max-w-64 overflow-hidden" :closeOnClick="true">
                <template v-slot:field>
                  <button class="btn btn-secondary " data-e2e="e2e-DD-protocol-assignedItems-selectInventory">
                    <div class="max-w-40 overflow-hidden truncate" :title="selectedRepository.attributes.name">{{ selectedRepository.attributes.name}}</div>
                    <i class="sn-icon sn-icon-down" aria-hidden="true"></i>
                  </button>
                </template>
                <template v-slot:flyout>
                  <div class="max-w-64 overflow-hidden" data-e2e="e2e-DO-protocol-assignedItemsModal-selectInventory">
                    <div
                      @click="openAssignItemModal = true"
                      class="block whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5 relative"
                      data-e2e="e2e-DO-protocol-assignedItemsModal-selectInventory-assignFromAnotherInventory"
                    >
                      {{ i18n.t('my_modules.repository.assigned_items_modal.assign_new_row') }}
                    </div>
                    <hr class="my-0">
                    <div v-for="(repository, index) in assignedRepositories" :key="repository.id"
                      @click="selectedRepository = repository"
                      :title="repository.attributes.name"
                      :class="{'bg-sn-super-light-blue': selectedRepository && selectedRepository.id === repository.id }"
                      class="flex items-center gap-2 truncate whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5 relative"
                    >
                      <div class="max-overflow-hidden truncate" :title="repository.attributes.name">
                        {{ repository.attributes.name }}
                      </div>
                      <div v-if="repository.attributes.shared" class="flex sn-icon sn-icon-teams-small ml-auto"></div>
                    </div>
                  </div>
                </template>
              </GeneralDropdown>
            </template>
          </div>
          <h4 class="modal-title truncate !block !w-48 !mr-0" data-e2e="e2e-TX-protocol-assignedItems-title">
            {{ i18n.t('my_modules.repository.assigned_items_modal.title') }}
          </h4>
        </div>
        <div class="modal-body !pb-0 min-h-[540px]">
          <AssignedRepository
            v-if="selectedRepository"
            :key="selectedRepository.id"
            :repository="selectedRepository"
            :myModuleId="myModuleId"
            :onlyRepository="true"
            @assignRows="assignRows"
            :reloadKey="reloadKey"
          />
          <div
            v-else-if="!initialLoading"
            class="flex flex-col min-h-[540px] items-center justify-center gap-1 ">
            <h2 class="text-sn-grey" data-e2e="e2e-TX-protocol-assignedItems-empty">
              {{ i18n.t('my_modules.repository.assigned_items_modal.empty_placeholder') }}
            </h2>
            <button
              @click="openAssignItemModal = true"
              class="btn btn-primary"
              data-e2e="e2e-BT-protocol-assignedItemsModal-empty-assignItems"
            >
              <i class="sn-icon sn-icon-new-task"></i>
              {{ i18n.t('my_modules.repository.assign_items') }}
            </button>
          </div>
        </div>
      </div>
    </div>
    <Teleport to="body">
      <AssignItemModal
        v-if="openAssignItemModal"
        :myModuleId="myModuleId"
        @assignRows="assignRows"
        @close="openAssignItemModal = false"
        :e2eValue="'task-assignedItems-assignItemModal'"/>
    </Teleport>
  </div>
</template>

<script>
/* global HelperModule I18n */

import GeneralDropdown from '../../shared/general_dropdown.vue';
import AssignedRepository from '../../my_module/assigned_items/repository.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin.js';
import AssignItemModal from '../../my_module/assigned_items/modals/assign_item.vue';
import {
  my_module_repositories_list_path,
  my_module_repository_path
} from '../../../routes.js';

export default {
  name: 'AssignedItems',
  mixins: [modalMixin],
  props: {
    myModuleId: {
      type: Number,
      required: true
    }
  },
  components: {
    AssignedRepository,
    GeneralDropdown,
    AssignItemModal
  },
  data() {
    return {
      assignedRepositories: [],
      selectedRepository: null,
      openAssignItemModal: false,
      initialLoading: true,
      reloadKey: 0
    };
  },
  computed: {
    assignedRepositoriesUrl() {
      return my_module_repositories_list_path(this.myModuleId);
    }
  },
  created() {
    this.loadAssignedRepositories();
  },
  methods: {
    loadAssignedRepositories(repositoryId = null) {
      axios.get(this.assignedRepositoriesUrl)
        .then((response) => {
          this.assignedRepositories = response.data.data;
          if (this.assignedRepositories.length > 0 && !this.selectedRepository ) {
            this.selectedRepository = this.assignedRepositories[0];
          }
          if (repositoryId) {
            const repository = this.assignedRepositories.find(repo => repo.id == repositoryId);
            if (repository) {
              this.selectedRepository = repository;
            }
          }
          this.initialLoading = false;
        });
    },
    assignRows(rowIds, repositoryId, assignToDownstream = false) {
      axios.patch(my_module_repository_path(this.myModuleId, repositoryId), {
        rows_to_assign: rowIds,
        downstream: assignToDownstream
      }).then((response) => {
        this.openAssignItemModal = false;
        HelperModule.flashAlertMsg(response.data.flash, 'success');
        this.reloadKey = this.reloadKey + 1;
        this.loadAssignedRepositories(repositoryId);
      });
    },
  }
};
</script>

