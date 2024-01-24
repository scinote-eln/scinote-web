<template>
  <inline-edit v-if="editable" class="item-name my-auto text-xl font-semibold" :value="name" :characterLimit="255"
    :characterMinLimit="0" :allowBlank="false" :smartAnnotation="false"
    :preventLeavingUntilFilled="true"
    :attributeName="`${i18n.t('repositories.item_card.header_title')}`" :singleLine="true"
    @editingEnabled="editingName = true" @editingDisabled="editingName = false" @update="updateName" @delete="handleDelete"></inline-edit>
  <h4 v-else class="item-name my-auto truncate text-xl" :title="computedName">
    {{ computedName }}
  </h4>
</template>

<script>
import InlineEdit from '../shared/inline_edit.vue';

export default {
  name: 'RepositoryItemSidebarTitle',
  components: {
    'inline-edit': InlineEdit
  },
  emits: ['update'],
  props: {
    editable: Boolean,
    name: String,
    archived: Boolean
  },
  computed: {
    computedName() {
      return this.archived ? `(A) ${this.name}` : this.name;
    }
  },
  methods: {
    updateName(name) {
      this.$emit('update', { repository_row: { name } });
    }
  }
};
</script>
