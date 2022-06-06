<template>
  <div class="protocol-metadata">
    <div class="data-block">
      <span class="fas block-icon fa-calendar-alt"></span>
      {{ i18n.t("protocols.header.created_at") }}
      {{ protocol.attributes.created_at_formatted }}
    </div>
    <div class="data-block">
      <span class="fas block-icon fa-user"></span>
      {{ i18n.t("protocols.header.added_by") }}
      <img :src="protocol.attributes.added_by.avatar"/>
      {{ protocol.attributes.added_by.name }}
    </div>
    <div class="data-block">
      <span class="fas block-icon fa-edit"></span>
      {{ i18n.t("protocols.header.updated_at") }}
      {{ protocol.attributes.updated_at_formatted }}
    </div>
    <div class="data-block">
      <span class="fas block-icon fa-graduation-cap"></span>
      {{ i18n.t("protocols.header.authors") }}
      <InlineEdit
        v-if="protocol.attributes.urls.update_protocol_authors_url"
        :value="protocol.attributes.authors"
        :placeholder="i18n.t('protocols.header.no_authors')"
        :allowBlank="true"
        :attributeName="`${i18n.t('Protocol')} ${i18n.t('authors')}`"
        @update="updateAuthors"
      />
      <span v-else>
        {{ protocol.attributes.authors }}
      </span>
    </div>
    <div class="data-block">
      <span class="fas block-icon fa-font"></span>
      {{ i18n.t("protocols.header.keywords") }}
      <DropdownSelector
        :inputTagMode="true"
        :options="this.protocol.attributes.keywords"
        :selectorId="'keywordsSelector'"
        :singleSelect="false"
        :closeOnSelect="false"
        :noEmptyOption="false"
        :selectAppearance="'tag'"
        :viewMode="protocol.attributes.urls.update_protocol_keywords_url == null"
        @dropdown:changed="updateKeywords"
      />
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
      }
    }
  }
</script>
