<template>
  <div ref="inputContainer" class="w-full h-10 flex flex-col justify-center">
    <div v-if="!editing && this.params.data.name.length > 0" class="ml-[3px]" @click="startEditing">{{ tagName }}</div>
    <template v-else>
      <input
        type="text"
        ref="nameInput"
        class="sci-table-input"
        :class="{ 'error': error }"
        @keydown.enter="saveName"
        @keydown.escape="cancelEditing"
        @keydown="handleKeydown"
        v-model="tagName"
        @blur="saveName"
        @change="saveName" />
      <div v-if="error" class="text-xs text-sn-alert-passion">{{ error }}</div>
    </template>
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
      return this.tagName.length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH && this.tagName.length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH;
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
  mounted() {
    if (this.$refs.nameInput) {
      this.$nextTick(() => {
        this.$refs.nameInput.focus();
      });
    }
  },
  methods: {
    startEditing() {
      this.editing = true;
      this.$nextTick(() => {
        this.$refs.nameInput.focus();
      });
    },
    cancelEditing() {
      this.editing = false;
      this.tagName = this.params.data.name;
      this.error = null;
      this.params.dtComponent.cancelCreation();
    },
    handleKeydown(event) {
      // Prevent arrow keys from moving the table selection
      if (event.key === 'ArrowLeft') {
        event.stopPropagation();
        this.$refs.nameInput.selectionStart -= 1;
      } else if (event.key === 'ArrowRight') {
        event.stopPropagation();
        this.$refs.nameInput.selectionEnd += 1;
      } else if (event.key === 'Home') {
        event.stopPropagation();
        this.$refs.nameInput.selectionStart = 0;
      } else if (event.key === 'End') {
        event.stopPropagation();
        this.$refs.nameInput.selectionEnd = this.tagName.length;
      }
    },
    saveName() {
      if (!this.isValid) {
        if (this.tagName.length < GLOBAL_CONSTANTS.NAME_MIN_LENGTH) {
          this.error = this.i18n.t('tags.index.too_short_name', { count: GLOBAL_CONSTANTS.NAME_MIN_LENGTH });
        } else if (this.tagName.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
          this.error = this.i18n.t('tags.index.too_long_name', { count: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
        }
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
        this.params.dtComponent.createRow();
      }
    }
  }
};
</script>
