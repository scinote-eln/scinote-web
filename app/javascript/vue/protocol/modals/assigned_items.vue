<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" style="width: 90vw;">
      <div class="modal-content">
        <div class="modal-header">
          <div class="w-48 flex justify-end">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
          </div>
          <div class="mx-auto flex items-center gap-2">
            <template v-if="selectedRepository">
              {{ i18n.t('my_modules.repository.assigned_items_modal.inventory') }}
              <GeneralDropdown  ref="addFieldDropdown">
                <template v-slot:field>
                  <button class="btn btn-secondary">
                    {{ selectedRepository.attributes.name}}
                    <i class="sn-icon sn-icon-down" aria-hidden="true"></i>
                  </button>
                </template>
                <template v-slot:flyout>
                  <div>
                    <div @click="openAssignItemModal = true" class="block whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5 relative">
                      {{ i18n.t('my_modules.repository.assigned_items_modal.assign_new_row') }}
                    </div>
                    <hr class="my-0">
                    <div v-for="(repository, index) in assignedRepositories" :key="repository.id"
                      @click="selectedRepository = repository"
                      :class="{'bg-sn-super-light-blue': selectedRepository && selectedRepository.id === repository.id }"
                      class="block whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5 relative"
                    >
                      {{ repository.attributes.name }}
                    </div>
                  </div>
                </template>
              </GeneralDropdown>
            </template>
          </div>
          <h4 class="modal-title truncate !block !w-48 !mr-0">
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
        </div>
      </div>
    </div>
    <Teleport to="body">
      <AssignItemModal
        v-if="openAssignItemModal"
        :myModuleId="myModuleId"
        @assignRows="assignRows"
        @close="openAssignItemModal = false"/>
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
    loadAssignedRepositories() {
      axios.get(this.assignedRepositoriesUrl)
        .then((response) => {
          this.assignedRepositories = response.data.data;
          if (this.assignedRepositories.length > 0 && !this.selectedRepository ) {
            this.selectedRepository = this.assignedRepositories[0];
          }
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
        this.loadAssignedRepositories();
      });
    },
  }
};
</script>

