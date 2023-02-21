<template>
  <div>
    <div class="dropdown sci-dropdown protocol-options-dropdown">
      <button
        class="btn btn-secondary dropdown-toggle"
        type="button"
        id="dropdownProtocolOptions"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="true"
        tabindex="0"
      >
        <span class="fas fa-cog"></span>
        <span>{{ i18n.t("my_modules.protocol.options_dropdown.title") }}</span>
        <span class="caret"></span>
      </button>
      <ul
        class="dropdown-menu dropdown-menu-right"
        aria-labelledby="dropdownProtocolOptions"
      >
        <li>
          <a
            ref="loadProtocol"
            data-action="load-from-repository"
            @click="loadProtocol"
            :class="{ disabled: !protocol.attributes.urls.load_from_repo_url }"
          >
            <span class="fas fa-edit"></span>
            <span>{{ i18n.t("my_modules.protocol.options_dropdown.load_from_repo") }}</span>
          </a>
        </li>
        <li>
          <a
            data-toggle="modal"
            data-target="#newProtocolModal"
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
            <span class="fas fa-upload"></span>
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
            <span class="fas fa-undo"></span>
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
            <span class="fas fa-trash"></span>
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
import DeleteStepsModals from 'vue/protocol/modals/delete_steps'

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
