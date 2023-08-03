<template>
  <div>
    <div class="dropdown protocol-options-dropdown">
      <button
        class="btn btn-secondary dropdown-toggle"
        type="button"
        id="dropdownProtocolOptions"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="true"
        tabindex="0"
      >
        <span>{{ i18n.t("my_modules.protocol.options_dropdown.title") }}</span>
        <span class="sn-icon sn-icon-down"></span>
      </button>
      <ul
        class="dropdown-menu dropdown-menu-right"
        aria-labelledby="dropdownProtocolOptions"
      >
        <li v-if="protocol.attributes.urls.load_from_repo_url">
          <a
            ref="loadProtocol"
            data-action="load-from-repository"
            @click="loadProtocol"
          >
            <span class="sn-icon sn-icon-protocols-templates"></span>
            <span>{{ i18n.t("my_modules.protocol.options_dropdown.load_from_repo") }}</span>
          </a>
        </li>
        <li>
          <a
            data-toggle="modal"
            data-target="#newProtocolModal"
            v-bind:data-protocol-name="protocol.attributes.name"
            :class="{ disabled: !protocol.attributes.urls.save_to_repo_url }"
          >
            <span class="fas fa-save"></span>
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.save_to_repo")
            }}</span>
          </a>
        </li>
        <li>
          <a
            data-turbolinks="false"
            :href="protocol.attributes.urls.export_url"
            :class="{ disabled: !protocol.attributes.urls.export_url }"
          >
            <span class="sn-icon sn-icon-import"></span>
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.export")
            }}</span>
          </a>
        </li>
        <li v-if="protocol.attributes.urls.update_protocol_url">
          <a
            ref="updateProtocol"
            data-action="update-self"
            @click="updateProtocol"
          >
            <span class="fas fa-sync-alt"></span>
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.update_protocol")
            }}</span>
          </a>
        </li>
        <li v-if="protocol.attributes.urls.unlink_url">
          <a
            ref="unlinkProtocol"
            data-action="unlink"
            @click="unlinkProtocol"
          >
            <span class="fas fa-unlink"></span>
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.unlink")
            }}</span>
          </a>
        </li>
        <li v-if="protocol.attributes.urls.revert_protocol_url">
          <a
            ref="revertProtocol"
            data-action="revert"
            @click="revertProtocol"
          >
            <span class="sn-icon sn-icon-restore"></span>
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.revert_protocol")
            }}</span>
          </a>
        </li>
        <li v-if="canDeleteSteps">
          <a
            data-turbolinks="false"
            @click.prevent="openStepsDeletingModal()"
          >
            <span class="sn-icon sn-icon-delete"></span>
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.delete_steps")
            }}</span>
          </a>
        </li>
      </ul>
    </div>
    <DeleteStepsModals v-if="stepsDeleting" @confirm="deleteSteps" @close="closeStartStepsDeletingModal" />
  </div>
</template>

 <script>
import DeleteStepsModals from './modals/delete_steps'

export default {

  name: "ProtocolOptions",
  components: { DeleteStepsModals },
  data() {
    return {
      stepsDeleting: false
    }
  },
  props: {
    protocol: {
      type: Object,
      required: true,
    },
    canDeleteSteps: {
      type: Boolean,
      required: true
    }
  },
  mounted() {
    // Legacy global functions from app/assets/javascripts/my_modules/protocols.js
    initLoadFromRepository();
    initImport();
    initLinkUpdate();
  },
  methods: {
    openStepsDeletingModal() {
      this.stepsDeleting = true;
    },
    closeStartStepsDeletingModal() {
      this.stepsDeleting = false;
    },
    loadProtocol() {
      $.get(
        this.protocol.attributes.urls.load_from_repo_url + "?type=recent"
      ).success((data) => {
        $(this.$refs.loadProtocol).trigger("ajax:success", data);
      });
    },
    unlinkProtocol() {
      $.get(this.protocol.attributes.urls.unlink_url).success((data) => {
        $(this.$refs.unlinkProtocol).trigger("ajax:success", data);
      });
    },
    updateProtocol() {
      $.get(this.protocol.attributes.urls.update_protocol_url).success((data) => {
        $(this.$refs.updateProtocol).trigger("ajax:success", data);
      });
    },
    revertProtocol() {
      $.get(this.protocol.attributes.urls.revert_protocol_url).success((data) => {
        $(this.$refs.revertProtocol).trigger("ajax:success", data);
      });
    },
    deleteSteps() {
      this.$emit('protocol:delete_steps')
    }
  },
};
</script>
