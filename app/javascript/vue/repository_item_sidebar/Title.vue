<template>
  <inline-edit
    v-if="editable"
    class="item-name my-auto text-xl font-semibold"
    :value="name"
    :characterLimit="255"
    :characterMinLimit="0"
    :allowBlank="false"
    :smartAnnotation="false"
    :attributeName="`${i18n.t('Repository_row')} ${i18n.t('Name')} `"
    :singleLine="true"
    @editingEnabled="editingName = true"
    @editingDisabled="editingName = false"
    @update="updateName"
  ></inline-edit>
  <h4 v-else class="item-name my-auto truncate text-xl" :title="name">
    {{ name }}
  </h4>
</template>

<script>
  import InlineEdit from "../shared/inline_edit.vue";

export default {
  name: "RepositoryItemSidebarTitle",
  components: {
    "inline-edit": InlineEdit
  },
  props: {
    editable: Boolean,
    name: String,
  },
  methods: {
    updateName(name) {
      this.$emit('update', { 'repository_row': { name: name } });
    },
  },
};
</script>
