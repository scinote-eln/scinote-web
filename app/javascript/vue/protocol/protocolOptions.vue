<template>
  <div v-if="optionsAvailable">
    <div class="dropdown protocol-options-dropdown">
      <button
        class="btn btn-secondary dropdown-toggle"
        type="button"
        id="dropdownProtocolOptions"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="true"
        tabindex="0"
        data-e2e="e2e-DD-task-protocol-actions"
      >
        <span>{{ i18n.t("my_modules.protocol.options_dropdown.title") }}</span>
        <span class="sn-icon sn-icon-down"></span>
      </button>
      <ul
        class="dropdown-menu dropdown-menu-right rounded !p-2.5 sn-shadow-menu-sm"
        aria-labelledby="dropdownProtocolOptions"
      >
        <li v-if="protocol.attributes.urls.load_from_repo_url && !inRepository">
          <button class="sn-legacy-menu-item"
            ref="loadProtocol"
            data-action="load-from-repository"
            :disabled="addingStepsLocked"
            :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : null"
            @click="loadProtocol()"
            data-e2e="e2e-DO-task-protocol-actions-loadFromRepository"
          >
            <span>{{ i18n.t("my_modules.protocol.options_dropdown.load_from_repo") }}</span>
        </button>
        </li>
        <li v-if="protocol.attributes.urls.add_protocol_steps_url && !inRepository">
          <button class="sn-legacy-menu-item"
            data-turbolinks="false"
            :disabled="addingStepsLocked"
            :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : null"
            @click.prevent="createWithAi()"
          >
            <i class="sn-icon sn-icon-ai mr-1"></i>
            <span>{{ i18n.t("protocols.index.import_with_ai") }}</span>
          </button>
        </li>
        <li v-if="protocol.attributes.urls.add_protocol_steps_url">
          <button class="sn-legacy-menu-item"
            data-turbolinks="false"
            :disabled="addingStepsLocked"
            :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : null"
            @click.prevent="openAddStepsModal()"
            data-e2e="e2e-DO-task-protocol-actions-addProtocolSteps"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.add_protocol_steps")
            }}</span>
          </button>
        </li>
        <li v-if="!inRepository">
          <button class="sn-legacy-menu-item"
            data-toggle="modal"
            data-target="#newProtocolModal"
            v-bind:data-protocol-name="protocol.attributes.name"
            :class="{ disabled: !protocol.attributes.urls.save_to_repo_url }"
            data-e2e="e2e-DO-task-protocol-actions-saveAsNewTemplate"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.save_to_repo")
            }}</span>
          </button>
        </li>
        <li v-if="!inRepository">
          <button class="sn-legacy-menu-item"
            data-turbolinks="false"
            :href="protocol.attributes.urls.export_url"
            :class="{ disabled: !protocol.attributes.urls.export_url }"
            data-e2e="e2e-DO-task-protocol-actions-exportProtocol"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.export")
            }}</span>
          </button>
        </li>
        <li v-if="protocol.attributes.urls.update_protocol_url && !inRepository">
          <button class="sn-legacy-menu-item"
            ref="updateProtocol"
            data-action="update-self"
            @click="updateProtocol"
            :disabled="addingStepsLocked"
            :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : null"
            data-e2e="e2e-DO-task-protocol-actions-updateProtocol"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.update_protocol")
            }}</span>
          </button>
        </li>
        <li v-if="!inRepository && protocol.attributes.linked">
          <button class="sn-legacy-menu-item"
            ref="unlinkProtocol"
            data-action="unlink"
            :disabled="!protocol.attributes.urls.unlink_url"
            :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : null"
            @click="unlinkProtocol()"
            data-e2e="e2e-DO-task-protocol-actions-unlinkProtocol"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.unlink")
            }}</span>
          </button>
        </li>
        <li v-if="!inRepository && protocol.attributes.linked">
          <button class="sn-legacy-menu-item"
            ref="revertProtocol"
            data-action="revert"
            :disabled="!protocol.attributes.urls.revert_protocol_url"
            :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : null"
            @click="revertProtocol()"
            data-e2e="e2e-DO-task-protocol-actions-revertProtocol"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.revert_protocol")
            }}</span>
          </button>
        </li>
        <li v-if="canArchiveSteps || addingStepsLocked">
          <button class="sn-legacy-menu-item"
            data-turbolinks="false"
            :disabled="!protocol.attributes.urls.archive_steps_url"
            :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : null"
            @click.prevent="openStepsArchivingModal()"
            data-e2e="e2e-DO-task-protocol-actions-archiveAllSteps"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.archive_steps")
            }}</span>
          </button>
        </li>
        <li v-if="canDeleteSteps">
          <button class="sn-legacy-menu-item"
            data-turbolinks="false"
            @click.prevent="openStepsDeletingModal()"
            data-e2e="e2e-DO-task-protocol-actions-deleteAllSteps"
          >
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.delete_steps")
            }}</span>
          </button>
        </li>
      </ul>
    </div>
    <Teleport to="body">
      <DeleteStepsModals v-if="stepsDeleting" @confirm="deleteSteps" @close="closeStartStepsDeletingModal" />
      <ArchiveStepsModal v-if="stepsArchiving" @confirm="archiveSteps" @close="closeStepsArchivingModal" />
      <AddStepsModal v-if="stepsAdding" :protocol="protocol" @confirm="addSteps" @close="closeAddStepsModal" />
    </Teleport>
  </div>
</template>

<script>
import DeleteStepsModals from './modals/delete_steps';
import ArchiveStepsModal from './modals/archive_steps';
import AddStepsModal from './modals/add_protocol_steps';
import tooltipMixin from '../mixins/tooltipMixin';

export default {
  name: 'ProtocolOptions',
  components: { DeleteStepsModals, ArchiveStepsModal, AddStepsModal },
  mixins: [tooltipMixin],
  data() {
    return {
      stepsDeleting: false,
      stepsArchiving: false,
      stepsAdding: false
    };
  },
  props: {
    protocol: {
      type: Object,
      required: true
    },
    canDeleteSteps: {
      type: Boolean,
      required: true
    },
    canArchiveSteps: {
      type: Boolean,
      required: true
    },
    inRepository: {
      type: Boolean,
      required: true
    },
    addingStepsLocked: {
      type: Boolean,
      required: true
    }
  },
  mounted() {
    // Legacy global functions from app/assets/javascripts/my_modules/protocols.js
    if (!this.inRepository) {
      initLoadFromRepository();
      initLinkUpdate();
    }
  },
  computed: {
    optionsAvailable() {
      return (
        (this.protocol.attributes.urls.load_from_repo_url && !this.inRepository)
        || this.protocol.attributes.urls.add_protocol_steps_url
        || !this.inRepository
        || (this.protocol.attributes.urls.update_protocol_url && !this.inRepository)
        || (this.protocol.attributes.urls.unlink_url && !this.inRepository)
        || (this.protocol.attributes.urls.revert_protocol_url && !this.inRepository)
        || this.canDeleteSteps
      );
    }
  },
  methods: {
    openStepsArchivingModal() {
      this.stepsArchiving = true;
    },
    closeStepsArchivingModal() {
      this.stepsArchiving = false;
    },
    openStepsDeletingModal() {
      this.stepsDeleting = true;
    },
    closeStartStepsDeletingModal() {
      this.stepsDeleting = false;
    },
    openAddStepsModal() {
      this.stepsAdding = true;
    },
    closeAddStepsModal() {
      this.stepsAdding = false;
    },
    loadProtocol() {
      $.get(
        `${this.protocol.attributes.urls.load_from_repo_url}?type=recent`
      ).done((data) => {
        $(this.$refs.loadProtocol).trigger('ajax:success', data);
      });
    },
    unlinkProtocol() {
      $.get(this.protocol.attributes.urls.unlink_url).done((data) => {
        $(this.$refs.unlinkProtocol).trigger('ajax:success', data);
      });
    },
    updateProtocol() {
      $.get(this.protocol.attributes.urls.update_protocol_url).done((data) => {
        $(this.$refs.updateProtocol).trigger('ajax:success', data);
      });
    },
    revertProtocol() {
      $.get(this.protocol.attributes.urls.revert_protocol_url).done((data) => {
        $(this.$refs.revertProtocol).trigger('ajax:success', data);
      });
    },
    createWithAi() {
      const aiButton = document.querySelector('#importWithAI');
      aiButton.click();
    },
    deleteSteps() {
      this.$emit('protocol:delete_steps');
    },
    archiveSteps() {
      this.$emit('protocol:archive_steps');
    },
    addSteps(steps) {
      this.$emit('protocol:add_protocol_steps', steps);
    }
  }
};
</script>
