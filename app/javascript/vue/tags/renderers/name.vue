<template>
  <div class="w-full h-10 flex flex-col justify-center">
    <div v-if="!editing && this.params.data.name.length > 0" class="ml-[3px]" @click="startEditing">{{ tagName }}</div>
    <input v-else
      ref="nameInput"
      class="sci-table-input"
      :class="{ 'error': error }"
      @keydown.enter="saveName($event, true);"
      :placeholder="this.i18n.t('tags.index.tag_name_placeholder')"
      v-model="tagName"
      @blur="saveName"
      @change="saveName" />
    <div v-if="error" class="text-xs text-sn-alert-passion">{{ error }}</div>
  </div>
</template>

<script>
export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  computed: {
    isValid() {
      return this.tagName.length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    }
  },
  data() {
    return {
      editing: false,
      tagName: this.params.data.name,
      error: null,
      saving: false
    };
  },
  watch: {
    tagName(newVal) {
      if (!this.params.data.id) {
        this.params.dtComponent.setTemplateValue(newVal, 'name', this.isValid);
      }
    }
  },
  methods: {
    startEditing() {
      this.editing = true;
      this.$nextTick(() => {
        this.$refs.nameInput.focus();
      });
    },
    saveName(e, withSave = false) {
      if (!this.isValid) {
        this.error = this.i18n.t('tags.index.too_short_name', { count: GLOBAL_CONSTANTS.NAME_MIN_LENGTH });
        this.params.dtComponent.setTemplateValue(this.tagName, 'name', this.isValid);
        return;
      } else {
        this.error = null;
      }

      this.editing = false;

      if (this.tagName == this.params.data.name) return;

      if (this.saving) return;

      this.saving = true;

      if (this.params.data.id) {
        this.params.dtComponent.$emit('changeName', this.tagName, this.params.data);
      } else {
        this.params.dtComponent.setTemplateValue(this.tagName, 'name', this.isValid);

        if (withSave) this.params.dtComponent.createRow();
      }
    }
  }
};
</script>
