<template>
  <div class="protocol-section protocol-information">
    <div id="protocol-details" class="protocol-section-header">
      <div class="protocol-details-container">
        <a class="protocol-section-caret" role="button" data-toggle="collapse" href="#details-container" aria-expanded="false" aria-controls="details-container">
          <i class="fas fa-caret-right"></i>
          <span id="protocolDetailsLabel" class="protocol-section-title">
            <h2>
              {{ i18n.t("protocols.header.details") }}
            </h2>
            <span class="protocol-code" >{{ protocol.attributes.code }}</span>
          </span>
        </a>
      </div>
      <div class="actions-block">
        <a class="btn btn-light icon-btn pull-right" :href="protocol.attributes.urls.print_protocol_url" target="_blank">
          <span class="fas fa-print" aria-hidden="true"></span>
        </a>
        <button class="btn btn-light" @click="openVersionsModal">{{ i18n.t("protocols.header.versions") }}</button>
        <button v-if="protocol.attributes.urls.publish_url" @click="$emit('publish')" class="btn btn-primary">{{ i18n.t("protocols.header.publish") }}</button>
        <button v-if="protocol.attributes.urls.save_as_draft_url" @click="saveAsdraft" class="btn btn-secondary">{{ i18n.t("protocols.header.save_as_draft") }}</button>
        <button v-bind:disabled="protocol.attributes.disabled_drafting" v-if="protocol.attributes.disabled_drafting" @click="saveAsdraft" class="btn btn-secondary">{{ i18n.t("protocols.header.save_as_draft") }}</button>
      </div>
    </div>
    <div id="details-container" class="protocol-details collapse in">
      <div class="protocol-metadata">
        <p class="data-block">
          {{ i18n.t("protocols.header.version") }}
          <b>{{ protocol.attributes.version }}</b>
        </p>
        <p class="data-block">
          {{ i18n.t("protocols.header.updated_at") }}
          <b>{{ protocol.attributes.updated_at_formatted }}</b>
        </p>
        <p class="data-block">
          {{ i18n.t("protocols.header.created_at") }}
          <b>{{ protocol.attributes.created_at_formatted }}</b>
        </p>
        <p class="data-block">
          {{ i18n.t("protocols.header.added_by") }}
          <img :src="protocol.attributes.added_by.avatar"/>
          {{ protocol.attributes.added_by.name }}
        </p>
        <p class="data-block authors-data">
          <span>{{ i18n.t("protocols.header.authors") }}</span>
          <span class="authors-list" v-if="protocol.attributes.urls.update_protocol_authors_url">
            <InlineEdit
              :value="protocol.attributes.authors"
              :placeholder="i18n.t('protocols.header.add_authors')"
              :allowBlank="true"
              :attributeName="`${i18n.t('Protocol')} ${i18n.t('authors')}`"
              @update="updateAuthors"
            />
          </span>
          <span class="authors-list" v-else>
            {{ protocol.attributes.authors }}
          </span>
        </p>
        <p class="data-block keywords-data">
          <span>{{ i18n.t("protocols.header.keywords") }}</span>
          <span class="keywords-list">
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
              @dropdown:changed="updateKeywords"
            />
          </span>
        </p>
      </div>
    </div>
  </div>
</template>
<script>

  import InlineEdit from 'vue/shared/inline_edit.vue'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'

  export default {
    name: 'ProtocolMetadata',
    components: { InlineEdit, DropdownSelector },
    props: {
      protocol: {
        type: Object,
        required: true
      },
    },
    methods: {
      saveAsdraft() {
        $.post(this.protocol.attributes.urls.save_as_draft_url)
      },
      updateAuthors(authors) {
        $.ajax({
          type: 'PATCH',
          url: this.protocol.attributes.urls.update_protocol_authors_url,
          data: { protocol: { authors: authors } },
          success: (result) => {
            this.$emit('update', result.data.attributes)
          }
        });
      },
      updateKeywords(keywords) {
        $.ajax({
          type: 'PATCH',
          url: this.protocol.attributes.urls.update_protocol_keywords_url,
          data: { keywords: keywords },
          success: (result) => {
            this.$emit('update', result.data.attributes)
          }
        });
      },
      openVersionsModal() {
        $.get(this.protocol.attributes.urls.versions_modal_url, (data) => {
          let versionsModal = '#protocol-versions-modal'
          $('.protocols-show').append($.parseHTML(data.html));
          $(versionsModal).modal('show');
          inlineEditing.init();
          $(versionsModal).find('[data-toggle="tooltip"]').tooltip();

          // Remove modal when it gets closed
          $(versionsModal).on('hidden.bs.modal', () => {
            $(versionsModal).remove();
          });
        });
      }
    }
  }
</script>
