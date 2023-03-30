<template>
  <div class="protocol-metadata">
    <p class="data-block">
      <span class="fas block-icon fa-calendar-alt fa-fw"></span>
      {{ i18n.t("protocols.header.created_at") }}
      <b>{{ protocol.attributes.created_at_formatted }}</b>
    </p>
    <p class="data-block">
      <span class="fas block-icon fa-user fa-fw"></span>
      {{ i18n.t("protocols.header.added_by") }}
      <img :src="protocol.attributes.added_by.avatar"/>
      {{ protocol.attributes.added_by.name }}
    </p>
    <p class="data-block">
      <span class="fas block-icon fa-edit fa-fw"></span>
      {{ i18n.t("protocols.header.updated_at") }}
      <b>{{ protocol.attributes.updated_at_formatted }}</b>
    </p>
    <p class="data-block authors-data">
      <span class="fas block-icon fa-graduation-cap fa-fw"></span>
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
      <span class="fas block-icon fa-font fa-fw"></span>
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
</template>
<script>

  import InlineEdit from '../shared/inline_edit.vue'
  import DropdownSelector from '../shared/dropdown_selector.vue'

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
