<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div v-if="downstreamMode" class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" >
            {{ i18n.t('my_modules.repository.assign_modal.title_downstream') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('my_modules.repository.assign_modal.description', { number: downstreamModules.length }) }}</p>
          <ul>
            <li v-for="(module, index) in downstreamModules" :key="index">
              {{ module }}
              <span v-if="index == 0">{{ i18n.t('my_modules.repository.assign_modal.current') }}</span>
            </li>
          </ul>
          <p>{{ i18n.t('my_modules.repository.assign_modal.description_2') }}</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="assignRows(true)">
            {{ i18n.t('my_modules.repository.assign_modal.action') }}
          </button>
        </div>
      </div>
      <div v-else class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" >
            {{ i18n.t('my_modules.repository.assign_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <RowSelector
            @change="this.rowIds = $event"
            @repositoryChange="selectedRepositoryId = $event"
            :multiple="true"
            :preSelectedRepository="selectedRepositoryId"
            class="mb-4"
          ></RowSelector>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-secondary ml-auto" @click="downstreamMode = true" :disabled="!validRowIds">
            {{ i18n.t('my_modules.repository.assign_modal.action_task_and_downstream') }}
          </button>
          <button class="btn btn-primary" @click="assignRows()" :disabled="!validRowIds">
            {{ i18n.t('my_modules.repository.assign_modal.action_task') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../../../packs/custom_axios.js';
import modalMixin from '../../../shared/modal_mixin.js';
import RowSelector from '../../../shared/repository_row_selector.vue';
import {
  assign_modal_my_module_repository_path
} from '../../../../routes.js';

export default {
  name: 'AssignItemModal',
  props: {
    myModuleId: String,
    selectedRepositoryValue: String
  },
  components: {
    RowSelector,
  },
  mixins: [modalMixin],
  data() {
    return {
      selectedRepositoryId: null,
      rowIds: [],
      downstreamModules: [],
      downstreamMode: false
    };
  },
  computed: {
    validRowIds() {
      return this.rowIds && this.rowIds.length > 0;
    }
  },
  watch: {
    downstreamMode(newValue) {
      if (newValue) {
        this.loadMyModules();
      }
    }
  },
  created() {
    this.selectedRepositoryId = parseInt(this.selectedRepositoryValue, 10);
  },
  methods: {
    assignRows(assignToDownstream = false) {
      this.$emit('assignRows', this.rowIds, this.selectedRepositoryId, assignToDownstream);
    },
    loadMyModules() {
      // Load downstream modules that can be assigned to
      axios.get(assign_modal_my_module_repository_path(this.myModuleId, this.selectedRepositoryId))
      .then((response) => {
        this.downstreamModules = response.data.my_modules;
      });
    }
  }
};
</script>
