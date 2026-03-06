<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content" :data-e2e="`e2e-MD-${e2eValue}`">
        <div class="modal-header">
          <button
            type="button"
            class="close"
            data-dismiss="modal"
            aria-label="Close"
            :data-e2e="`e2e-BT-${e2eValue}-close`"
          >
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" :data-e2e="`e2e-TX-${e2eValue}-title`">
            {{ i18n.t('my_modules.repository.unassign_modal.title') }}
          </h4>
        </div>
        <div v-if="downstreamMode" class="modal-body">
          <p
            v-html="i18n.t('my_modules.repository.unassign_modal.message_downstream', { number: rowIds.length })"
            :data-e2e="`e2e-TX-${e2eValue}-downstreamMessage`"
          ></p>
          <ul :data-e2e="`e2e-TX-${e2eValue}-downstreamTasks`">
            <li v-for="(module, index) in downstreamModules" :key="index">
              {{ module }}
              <span v-if="index == 0">{{ i18n.t('my_modules.repository.unassign_modal.current') }}</span>
            </li>
          </ul>
          <p :data-e2e="`e2e-TX-${e2eValue}-confirmation`">
            {{ i18n.t('my_modules.repository.unassign_modal.confirmation') }}
          </p>
        </div>
        <div v-else class="modal-body">
          <p
            v-html="i18n.t('my_modules.repository.unassign_modal.message', { number: rowIds.length })"
            :data-e2e="`e2e-TX-${e2eValue}-message1`"
          ></p>
          <p :data-e2e="`e2e-TX-${e2eValue}-message2`">
            {{ i18n.t('my_modules.repository.unassign_modal.message_2') }}
          </p>
          <p :data-e2e="`e2e-TX-${e2eValue}-confirmation`">
            {{ i18n.t('my_modules.repository.unassign_modal.confirmation') }}
          </p>
        </div>
        <div class="modal-footer">
          <button
            type="button"
            class="btn btn-secondary"
            data-dismiss="modal"
            :data-e2e="`e2e-BT-${e2eValue}-cancel`"
          >
            {{ i18n.t('general.cancel') }}
          </button>
          <button
            v-if="downstreamMode"
            class="btn btn-primary"
            @click="unassignRows"
            :data-e2e="`e2e-BT-${e2eValue}-unassignDownstream`"
          >
            {{ i18n.t('my_modules.repository.unassign_modal.action_downstream') }}
          </button>
          <button
            v-else class="btn btn-primary"
            @click="unassignRows"
            :data-e2e="`e2e-BT-${e2eValue}-unassign`"
          >
            {{ i18n.t('my_modules.repository.unassign_modal.action') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../../../packs/custom_axios.js';
import modalMixin from '../../../shared/modal_mixin.js';
import {
  assign_modal_my_module_repository_path
} from '../../../../routes.js';

export default {
  name: 'UnassignItemModal',
  props: {
    myModuleId: String,
    rowIds: Array,
    downstreamMode: Boolean,
    selectedRepositoryId: String,
    e2eValue: {
      type: String,
      default: ''
    }
  },
  mixins: [modalMixin],
  data() {
    return {
      downstreamModules: []
    };
  },
  created() {
    if (this.downstreamMode) {
      this.loadMyModules();
    }
  },
  methods: {
    loadMyModules() {
      // Load downstream modules that can be assigned to
      axios.get(assign_modal_my_module_repository_path(this.myModuleId, this.selectedRepositoryId))
      .then((response) => {
        this.downstreamModules = response.data.my_modules;
      });
    },
    unassignRows() {
      this.$emit('unassignRows', this.rowIds, this.downstreamMode);
    }
  }
};
</script>
