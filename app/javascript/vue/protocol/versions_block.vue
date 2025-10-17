<template>
  <div v-if="protocol" class="flex items-center gap-2">
    <button class="btn btn-light" @click="openVersionsModal" data-e2e="e2e-BT-protocolTemplates-protocolDetails-versions">
      {{ i18n.t("protocols.header.versions") }}
    </button>
    <button v-if="protocol.attributes.urls.publish_url"
            @click="startPublish" class="btn btn-primary" data-e2e="e2e-BT-protocolTemplates-protocolDetails-publish">
      {{ i18n.t("protocols.header.publish") }}</button>
    <button v-if="protocol.attributes.urls.save_as_draft_url"
            :disabled="protocol.attributes.has_draft || creatingDraft"
            @click="saveAsdraft" class="btn btn-secondary" data-e2e="e2e-BT-protocolTemplates-protocolDetails-saveAsDraft">
      {{ i18n.t("protocols.header.save_as_draft") }}
    </button>
    <PublishProtocol v-if="publishing"
      :protocol="protocol"
      @publish="publishProtocol"
      @cancel="closePublishModal"
    />
    <VersionsModal v-if="VersionsModalObject" :protocol="VersionsModalObject"
      @close="VersionsModalObject = null"
      @reloadPage="reloadPage"
      @redirectToProtocols="redirectToProtocols"/>
  </div>
</template>

<script>
import PublishProtocol from './modals/publish_protocol.vue';
import VersionsModal from '../protocols/modals/versions.vue';
import axios from '../../packs/custom_axios';

export default {
  name: 'ProtocolVersions',
  props: {
    protocolUrl: {
      type: String,
      required: true
    }
  },
  components: {
    PublishProtocol,
    VersionsModal
  },
  data() {
    return {
      protocol: null,
      steps: [],
      publishing: false,
      VersionsModalObject: null,
      creatingDraft: false
    };
  },
  mounted() {
    this.fetchProtocol();
  },
  methods: {
    fetchProtocol() {
      axios.get(this.protocolUrl)
        .then((response) => {
          this.protocol = response.data.data;
        })
    },
    startPublish() {
      axios.get(this.protocol.attributes.urls.version_comment_url)
        .then((response) => {
          this.protocol.attributes.version_comment = response.data.version_comment;
          this.publishing = true;
        })
    },
    openVersionsModal() {
      this.VersionsModalObject = {
        id: this.protocol.id,
        name: this.protocol.attributes.name,
        urls: {
          versions_modal: this.protocol.attributes.urls.versions_modal
        }
      };
    },
    saveAsdraft() {
      if (this.creatingDraft) {
        return;
      }

      this.creatingDraft = true;

      axios.post(this.protocol.attributes.urls.save_as_draft_url)
        .then((response) => {
          this.creatingDraft = false;
          window.location.replace(response.data.url);
        })
        .catch(() => {
          this.creatingDraft = false;
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'));
        });
    },
    closePublishModal() {
      this.publishing = false;
    },
    publishProtocol(comment) {
      this.protocol.attributes.version_comment = comment;
      axios.post(this.protocol.attributes.urls.publish_url, {
        version_comment: comment,
        view: 'show'
      })
        .then((response) => {
          window.location.replace(response.data.url);
        })
    },
    reloadPage() {
      window.location.reload();
    },
    redirectToProtocols() {
      window.location.href = this.protocol.attributes.urls.redirect_to_protocols;
    }
  }
};
</script>
