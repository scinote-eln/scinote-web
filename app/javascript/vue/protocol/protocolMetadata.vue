<template>
  <div class="protocol-section protocol-information mb-4" data-e2e="e2e-CO-protocolTemplates-protocolDetails">
    <div id="protocol-details" class="protocol-section-header">
      <div class="protocol-details-container">
        <a class="protocol-section-caret" role="button" data-toggle="collapse"
           href="#details-container" aria-expanded="false" aria-controls="details-container">
          <i class="sn-icon sn-icon-right"></i>
          <span id="protocolDetailsLabel" class="protocol-section-title">
            <h2 data-e2e="e2e-TX-protocolTemplates-protocolDetails-title">
              {{ i18n.t("protocols.header.details") }}
            </h2>
            <span class="protocol-code" data-e2e="e2e-TX-protocolTemplates-protocolDetails-protocolId">{{ protocol.attributes.code }}</span>
          </span>
        </a>
      </div>
      <div class="actions-block">
        <a class="btn btn-light icon-btn pull-right"
           :href="protocol.attributes.urls.print_protocol_url" target="_blank"
           data-e2e="e2e-BT-protocolTemplates-protocolDetails-print">
          <span class="sn-icon sn-icon-printer" aria-hidden="true"></span>
        </a>
        <button class="btn btn-light" @click="openVersionsModal" data-e2e="e2e-BT-protocolTemplates-protocolDetails-versions">
          {{ i18n.t("protocols.header.versions") }}
        </button>
        <button v-if="protocol.attributes.urls.publish_url"
                @click="$emit('publish')" class="btn btn-primary" data-e2e="e2e-BT-protocolTemplates-protocolDetails-publish">
          {{ i18n.t("protocols.header.publish") }}</button>
        <button v-if="protocol.attributes.urls.save_as_draft_url"
                :disabled="protocol.attributes.has_draft || creatingDraft"
                @click="saveAsdraft" class="btn btn-secondary" data-e2e="e2e-BT-protocolTemplates-protocolDetails-saveAsDraft">
          {{ i18n.t("protocols.header.save_as_draft") }}
        </button>
      </div>
    </div>
    <div id="details-container" class="protocol-details collapse in">
      <div class="protocol-metadata">
        <p class="data-block">
          <span data-e2e="e2e-TX-protocolTemplates-protocolDetails-versionLabel">{{ i18n.t("protocols.header.version") }}</span>
          <b data-e2e="e2e-TX-protocolTemplates-protocolDetails-version">{{ titleVersion }}</b>
        </p>
        <p class="data-block" v-if="protocol.attributes.published">
          <span data-e2e="e2e-TX-protocolTemplates-protocolDetails-publishedOnLabel">{{ i18n.t("protocols.header.published_on") }}</span>
          <b data-e2e="e2e-TX-protocolTemplates-protocolDetails-publishedOn">{{ protocol.attributes.published_on_formatted }}</b>
        </p>
        <p class="data-block" v-if="protocol.attributes.published" data-e2e="e2e-TX-protocolTemplates-protocolDetails-publishedBy">
          <span>{{ i18n.t("protocols.header.published_by") }}</span>
          <img :src="protocol.attributes.published_by.avatar" class="rounded-full"/>
          {{ protocol.attributes.published_by.name }}
        </p>
        <p class="data-block">
          <span data-e2e="e2e-TX-protocolTemplates-protocolDetails-updatedAtLabel">{{ i18n.t("protocols.header.updated_at") }}</span>
          <b data-e2e="e2e-TX-protocolTemplates-protocolDetails-updatedAt">{{ protocol.attributes.updated_at_formatted }}</b>
        </p>
        <p class="data-block">
          <span data-e2e="e2e-TX-protocolTemplates-protocolDetails-createdAtLabel">{{ i18n.t("protocols.header.created_at") }}</span>
          <b data-e2e="e2e-TX-protocolTemplates-protocolDetails-createdAt">{{ protocol.attributes.created_at_formatted }}</b>
        </p>
        <p class="data-block" data-e2e="e2e-TX-protocolTemplates-protocolDetails-createdBy">
          <span>{{ i18n.t("protocols.header.added_by") }}</span>
          <img :src="protocol.attributes.added_by.avatar" class="rounded-full"/>
          {{ protocol.attributes.added_by.name }}
        </p>
        <p class="data-block authors-data">
          <span data-e2e="e2e-TX-protocolTemplates-protocolDetails-authorsLabel">{{ i18n.t("protocols.header.authors") }}</span>
          <span class="authors-list" v-if="protocol.attributes.urls.update_protocol_authors_url">
            <InlineEdit
              :value="protocol.attributes.authors"
              :placeholder="i18n.t('protocols.header.add_authors')"
              :allowBlank="true"
              :attributeName="`${i18n.t('Protocol')} ${i18n.t('protocols.header.authors_list')}`"
              :characterLimit="10000"
              :dataE2e="'protocolTemplates-protocolDetails-authors'"
              @update="updateAuthors"
            />
          </span>
          <span class="authors-list" data-e2e="e2e-TX-protocolTemplates-protocolDetails-authorsPublished" v-else>
            {{ protocol.attributes.authors }}
          </span>
        </p>
        <p class="data-block keywords-data">
          <span data-e2e="e2e-TX-protocolTemplates-protocolDetails-keywordsLabel">{{ i18n.t("protocols.header.keywords") }}</span>
          <span
            class="keywords-list"
            v-if="protocol.attributes.urls.update_protocol_authors_url || protocol.attributes.keywords.length">
            <DropdownSelector
              :inputTagMode="true"
              :options="this.protocol.attributes.keywords"
              :placeholder="i18n.t('protocols.header.add_keywords')"
              :selectorId="'keywordsSelector'"
              :singleSelect="false"
              :closeOnSelect="false"
              :noEmptyOption="false"
              :selectAppearance="'tag'"
              :viewMode="protocol.attributes.urls.update_protocol_keywords_url == null"
              :dataE2e="'protocolTemplates-protocolDetails-keywords'"
              @dropdown:changed="updateKeywords"
            />
          </span>
        </p>
      </div>
    </div>
  </div>
  <Teleport to="body">
    <VersionsModal v-if="VersionsModalObject" :protocol="VersionsModalObject"
                 @close="VersionsModalObject = null"
                 @reloadPage="reloadPage"
                 @redirectToProtocols="redirectToProtocols"/>
  </Teleport>
</template>
<script>
/* global HelperModule */
import InlineEdit from '../shared/inline_edit.vue';
import DropdownSelector from '../shared/legacy/dropdown_selector.vue';
import VersionsModal from '../protocols/modals/versions.vue';

export default {
  name: 'ProtocolMetadata',
  components: { InlineEdit, DropdownSelector, VersionsModal },
  props: {
    protocol: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      VersionsModalObject: null,
      creatingDraft: false
    };
  },
  computed: {
    titleVersion() {
      const createdFromVersion = this.protocol.attributes.created_from_version;

      if (this.protocol.attributes.published) {
        return this.protocol.attributes.version;
      }

      if (!createdFromVersion) {
        return this.i18n.t('protocols.draft');
      }

      return this.i18n.t('protocols.header.draft_with_from_version', { nr: createdFromVersion });
    }
  },
  methods: {
    saveAsdraft() {
      if (this.creatingDraft) {
        return;
      }

      this.creatingDraft = true;

      $.post(this.protocol.attributes.urls.save_as_draft_url, (result) => {
        this.creatingDraft = false;
        window.location.replace(result.url);
      }).error(() => {
        this.creatingDraft = false;
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'));
      });
    },
    updateAuthors(authors) {
      $.ajax({
        type: 'PATCH',
        url: this.protocol.attributes.urls.update_protocol_authors_url,
        data: { protocol: { authors } },
        success: (result) => {
          this.$emit('update', result.data.attributes);
        },
        error: (data) => {
          let message;
          if (data.responseJSON) {
            message = Object.values(data.responseJSON).join(', ');
          } else {
            message = this.i18n.t('errors.general');
          }
          HelperModule.flashAlertMsg(message);
        }
      });
    },
    updateKeywords(keywords) {
      const uniqueKeywords = [...new Set(keywords.map((kw) => kw.trim()).filter((kw) => !!kw))];
      $.ajax({
        type: 'PATCH',
        url: this.protocol.attributes.urls.update_protocol_keywords_url,
        data: { keywords: uniqueKeywords },
        success: (result) => {
          this.$emit('update', result.data.attributes);
        }
      });
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
    reloadPage() {
      window.location.reload();
    },
    redirectToProtocols() {
      window.location.href = this.protocol.attributes.urls.redirect_to_protocols;
    }
  }
};
</script>
