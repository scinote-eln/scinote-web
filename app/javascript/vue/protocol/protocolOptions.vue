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
            ref="saveProtocol"
            data-action="copy-to-repository"
            @click="saveProtocol"
            :class="{ disabled: !protocol.attributes.urls.save_to_repo_url }"
          >
            <span class="fas fa-check"></span>
            <span>{{
              i18n.t("my_modules.protocol.options_dropdown.save_to_repo")
            }}</span>
          </a>
        </li>
        <li>
          <a data-action="load-from-file"
              class="btn-open-file"
              :data-import-url="protocol.attributes.urls.import_url"
              :class="{ disabled: !protocol.attributes.urls.import_url }">
            <span class="fas fa-download"></span>
            <span>{{ i18n.t("my_modules.protocol.options_dropdown.import") }}</span>
            <input type="file" value="" accept=".eln" data-turbolinks="false">
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
    initCopyToRepository();
    initImport();
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
    saveProtocol() {
      $.get(this.protocol.attributes.urls.save_to_repo_url).success((data) => {
        $(this.$refs.saveProtocol).trigger("ajax:success", data);
      });
    },
    deleteSteps() {
      this.$emit('protocol:delete_steps')
    }
  },
};
</script>
